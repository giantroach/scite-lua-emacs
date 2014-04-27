-- Common Lua Functions

-- Insert indent depending on settings...
function DoIndent(CursorMove)
    if editor.UseTabs then
        editor:InsertText(editor.CurrentPos, "\t")
        if CursorMove then
            editor:GotoPos(editor.CurrentPos+1)
        end
    else
        for i=1, editor.TabWidth do
            editor:InsertText(editor.CurrentPos, " ")
            if CursorMove then
                editor:GotoPos(editor.CurrentPos+1)
            end
        end
    end
end


-- Calculate no. of indent of line where caret located.
function GetIndentNum()
    local result = math.floor(editor.LineIndentation[editor:LineFromPosition(editor.CurrentPos-1)]/editor.TabWidth)
    return result
end


-- Check if previous word is the given one.
-- By default, this ignores just one character before the caret, since it assumed to be used in keypress callback.
-- Use offset arg for another purpose.
function IsTheWord(word, offset)
    if offset then
--~         print("is '"..editor:textrange(editor.CurrentPos+offset, editor.CurrentPos+offset+string.len(word)).."'=='"..word.."'?")
        if editor:textrange(editor.CurrentPos+offset, editor.CurrentPos+offset+string.len(word))==word then
            return true
        else
            return false
        end
        
    else
--~         print("is '"..editor:textrange(editor.CurrentPos-string.len(word)-1, editor.CurrentPos-1).."'=='"..word.."'?")
        if editor:textrange(editor.CurrentPos-string.len(word)-1, editor.CurrentPos-1)==word then
            return true
        else
            return false
        end
    end
end


-- Return a words from caret position to given delimiter
function FindPrevWord(dlmter, readIdx)
    local lineStr, idx, lineStrTillCur, hasDlm, i, j, val, dlmterIdx, chr

    lineStr, idx = editor:GetCurLine()
    if readIdx then
        lineStrTillCur = string.sub(lineStr, 0, readIdx - 1)
    else
        lineStrTillCur = string.sub(lineStr, 0, idx - 1)
    end

    -- if it's first pos of doc
    if lineStrTillCur == "" then
        return "", 0
    end

    --to reduce the number of comparation, first check if there's delimiter
    hasDlm = false
    for i, val in ipairs(dlmter) do
        if string.find(lineStrTillCur, val) ~= nil then
            hasDlm = true
            break
        end
    end
    --As there's no delimiter, just return the line
    if not(hasDlm) then
        return lineStrTillCur, 0
    end

    dlmterIdx = 0

    --iterate backwords from cur pos.
    for i = (idx - 1), 0, -1 do
        chr = string.sub(lineStrTillCur, i, i)

        for j, val in ipairs(dlmter) do
            if val == chr then
                dlmterIdx = i
                break
            end
        end

        if dlmterIdx ~= 0 then
            break
        end
    end

    return string.sub(lineStrTillCur, dlmterIdx + 1, idx - 1), dlmterIdx
end


-- for testing purpose...
function WhatIsTheWord(word, offset)
    local result
    if offset then
        result = editor:textrange(editor.CurrentPos+offset, editor.CurrentPos+offset+string.len(word))
        print(result)
--~         return result
        
    else
        result = editor:textrange(editor.CurrentPos-string.len(word)-1, editor.CurrentPos-1)
        print(result)
--~         return result
    end
end
