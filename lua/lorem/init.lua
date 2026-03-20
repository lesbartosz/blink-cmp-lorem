local generator = require("lorem.generator")
local default_words = require("lorem.words")

local DEFAULTS = {
  classic_start      = false,
  variants           = 1,
  min_sentence_words = 3,
  max_sentence_words = 15,
  comma_per_words    = 3,
  comma_chance       = 0.6,
  words              = default_words,
}

local TRIGGER_PATTERN = "Lorem(%d+)$"
local LOREM_PREFIX_LEN = #"Lorem"
local PREVIEW_WORD_LIMIT = 16

local Source = {}
Source.__index = Source

function Source.new(opts)
  local config = vim.tbl_deep_extend("force", DEFAULTS, opts or {})

  assert(config.min_sentence_words >= 1,
    "lorem: min_sentence_words must be >= 1")
  assert(config.max_sentence_words >= config.min_sentence_words,
    "lorem: max_sentence_words must be >= min_sentence_words")
  assert(config.comma_per_words >= 1,
    "lorem: comma_per_words must be >= 1")
  assert(config.comma_chance >= 0 and config.comma_chance <= 1,
    "lorem: comma_chance must be in 0..=1 range")
  assert(#config.words >= 1,
    "lorem: words table must not be empty")
  assert(config.variants >= 1,
    "lorem: variants must be >= 1")

  return setmetatable({ config = config }, Source)
end

function Source:get_trigger_characters()
  return { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
end

function Source:enabled(ctx)
  if not ctx then return true end
  local before = ctx.line:sub(1, ctx.cursor[2])
  return before:match(TRIGGER_PATTERN) ~= nil
end

local function make_preview(text)
  local words = {}
  for word in text:gmatch("%S+") do
    words[#words + 1] = word
    if #words >= PREVIEW_WORD_LIMIT then break end
  end
  return table.concat(words, " ") .. "..."
end

local function make_range(cursor_row, start_char, cursor_char)
  return {
    start   = { line = cursor_row, character = start_char },
    ["end"] = { line = cursor_row, character = cursor_char },
  }
end

function Source:get_completions(ctx, callback)
  local before = ctx.line:sub(1, ctx.cursor[2])
  local raw_n = before:match(TRIGGER_PATTERN)
  local word_count = raw_n and tonumber(raw_n)

  if not word_count or word_count < 1 then
    return callback(nil)
  end

  local cursor_row = ctx.cursor[1]
  local cursor_char = ctx.cursor[2]
  local start_char = cursor_char - LOREM_PREFIX_LEN - #raw_n

  local items = {}
  for _ = 1, self.config.variants do
    local text = generator.generate(word_count, self.config)

    items[#items + 1] = {
      label = make_preview(text),
      filterText = string.format("Lorem%d", word_count),
      kind = 1, -- Text
      documentation = { kind = "plaintext", value = text },

      textEdit = {
        newText = text,
        range   = make_range(cursor_row, start_char, cursor_char),
      },
    }
  end

  callback({
    is_incomplete_forward  = true,
    is_incomplete_backward = false,
    items                  = items,
  })
end

return Source
