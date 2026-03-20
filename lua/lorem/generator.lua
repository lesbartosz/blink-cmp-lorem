local M = {}

math.randomseed(os.time())

--- Roll how many commas to place in a sentence of `length` words
local function roll_commas(length, config)
  local inner = math.max(0, length - 2)
  local max_slots = math.max(0, math.floor(length / config.comma_per_words))
  max_slots = math.min(max_slots, inner)

  local count = 0
  for _ = 1, max_slots do
    if math.random() < config.comma_chance then
      count = count + 1
    end
  end

  return count
end

--- Build one sentence of `length` words drawn from `word_pool`
local function build_sentence_words(length, word_pool, config)
  local words = {}
  for _ = 1, length do
    words[#words + 1] = word_pool[math.random(#word_pool)]
  end

  -- Decide comma positions via partial Fisher-Yates
  local num_commas = roll_commas(length, config)
  local comma_at   = {} -- Set of word indices that get a trailing comma

  if num_commas > 0 then
    local candidates = {}
    for i = 2, length - 1 do
      candidates[#candidates + 1] = i
    end

    for i = 1, num_commas do
      local j = math.random(i, #candidates)
      candidates[i], candidates[j] = candidates[j], candidates[i]
      comma_at[candidates[i]] = true
    end
  end

  -- Assemble the sentence string
  local parts = {}
  for i, w in ipairs(words) do
    parts[#parts + 1] = comma_at[i] and (w .. ",") or w
  end

  return table.concat(parts, " ")
end

--- Generate Lorem ipsum text of exactly `word_count` total words
function M.generate(word_count, config)
  local word_pool = config.words
  local sentences = {}
  local words_remaining = word_count

  while words_remaining > 0 do
    local length = math.min(
      math.random(config.min_sentence_words, config.max_sentence_words),
      words_remaining
    )

    if #sentences == 0 and config.classic_start and word_count > 5 then
      length = math.max(length, 5)
    end

    local words = build_sentence_words(length, word_pool, config)

    if #sentences == 0 and config.classic_start then
      local prefix = { "Lorem", "ipsum", "dolor", "sit", "amet," }
      local parts = {}
      local i = 0

      for w in words:gmatch("%S+") do
        i = i + 1
        local pw = (i <= #prefix) and prefix[i] or w:gsub(",$", "")
        parts[i] = pw
      end

      words = table.concat(parts, " ")
    end

    local sentence = words:sub(1, 1):upper() .. words:sub(2)
    sentences[#sentences + 1] = sentence:gsub(",$", "") .. "."
    words_remaining = words_remaining - length
  end

  return table.concat(sentences, " ")
end

return M
