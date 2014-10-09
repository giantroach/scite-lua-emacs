-- emacs like keybind function
function emacs()
    local inRegion = false
    local inCx = false
    local inMx = false
    local inSrch = false
    local lastSrchPos = ""
    local lastKc = 0
    local lastCmd = "none"
    local mXBuffer = {}
    local LINEFEED = "\n"

    local killring = {}
    local killring_lastcpos = -1
    local killring_MAX = 10

    --name is push but kinda unshift
    local function killring_push(val)
        table.insert(killring, 1, val)
        if table.getn(killring) > killring_MAX then
            table.remove(killring)
        end
    end

    --shift top item of killring and push back
    local function killring_shift()
        local top = table.remove(killring, 1)
        table.insert(killring, top)
        return killring[1]
    end

    --pop last item of killring and unshift back
    local function killring_unshift()
        local tail = table.remove(killring)
        table.insert(killring, 1, top)
        return killring[table.getn(killring)]
    end

    --show killring
    local function killring_show()
        local i
        local killring_strlist = ""

        function strShrink(str)
            local firstPos = string.find(str, "[\r\n]")
            if firstPos then
              str = string.sub(str, 0, firstPos)
            end
            return str
        end

        if table.getn(killring) > 1 then
            if editor:CallTipActive() then
                editor:CallTipCancel()
            end
            killring_strlist = strShrink(killring[1])
            for i = 2, table.getn(killring) do
                killring_strlist = killring_strlist .. LINEFEED .. strShrink(killring[i])
            end
            editor:CallTipShow(editor.CurrentPos, killring_strlist)
        end
    end

    --hide killring (simply hide calltip)
    local function killring_hide()
        if editor:CallTipActive() then
            editor:CallTipCancel()
        end
    end

    --show search box with clipboard if no selection is made
    local function searchWithClipBoard()
        local txt = editor:GetSelText()
        if string.len(txt) > 0 then
            scite.MenuCommand(IDM_FIND)
        else
            local src = editor.CurrentPos
            editor:Paste()
            local dst = editor.CurrentPos
            editor:SetSel(src, dst)
            scite.MenuCommand(IDM_FIND)
            editor:Undo()
        end
    end

    -- --------------------------------
    -- OnKey call back starts here
    --
    return function (kc, shift, ctrl, alt, xxx)
--~         print("kc:" .. kc)
--~         print("last kc was.."..lastKc)
--~         print('char:'..string.char(kc))
        lastKc = kc


        -- --------------------------------
        -- M-x combination
        --
        if inMx then
            if ctrl and kc == 71 then --g
                lastCmd = "C-g"
                inMx = false
                return true
            end

            if (ctrl and kc == 72) or kc == 127 then -- C-h or delete
                table.remove(mXBuffer)
                output:LineEnd()
                output:DeleteBack()
                return true
            end

            if kc == 13 or (ctrl and kc == 77) then -- enter / C-m
                local cmd = string.lower(table.concat(mXBuffer))

                if cmd == "vim" then
                    if activateOnkey("vim") then
                        print("")
                        print('vim activated')
                        lastCmd = "M-x vim"
                        inMx = false
                        return true
                    end
                end

                lastCmd = "M-x unknown"
                inMx = false
                print("")
                print("Unknown command: "..cmd)
                return true
            end

            table.insert(mXBuffer, string.char(kc))
            output:LineEnd()
            output:InsertText(output.CurrentPos, string.lower(string.char(kc)))
            return true
        end


        -- --------------------------------
        --C-x combination
        --
        if inCx then
            if ctrl then
                if kc == 70 then --f
                    lastCmd = "C-x C-f"
                    scite.MenuCommand(IDM_OPEN)
                    inCx = false
                    return true
                end

                if kc == 83 then --s
                    lastCmd = "C-x C-s"
                    scite.MenuCommand(IDM_SAVE)
                    inCx = false
                    return true
                end

                if kc == 67 then --c
                    lastCmd = "C-x C-c"
                    scite.MenuCommand(IDM_QUIT)
                    inCx = false
                    return true
                end

                if kc == 66 then --b
                    lastCmd = "C-x C-b"
                    scite.MenuCommand(IDM_PREVFILE)
                    inCx = false
                    return true
                end
            end

            if kc == 66 then --b
                lastCmd = "C-x b"
                scite.MenuCommand(IDM_NEXTFILE)
                inCx = false
                return true
            end

            if kc == 72 then --h
                lastCmd = "C-x h"
                editor:SelectAll()
                inCx = false
                return true
            end

            if kc == 75 then --k
                lastCmd = "C-x k"
                scite.MenuCommand(IDM_CLOSE)
                inCx = false
                return true
            end

            if kc == 82 then --r
                lastCmd = "C-x r"
                scite.MenuCommand(IDM_BOOKMARK_TOGGLE)
                inCx = false
                return true
            end

            if kc == 85 then --u
                lastCmd = "C-x u"
                editor:Undo()
                inRegion = false
                inCx = false
                inMx = false
                return true
            end

            inCx = false
            return true
        end


        -- --------------------------------
        -- C-M combination
        --
        if ctrl and alt then
            if kc == 78 then --n
                lastCmd = "C-M-n"
                scite.MenuCommand(IDM_MATCHBRACE)
                return true
            end

            if kc == 80 then --p
                lastCmd = "C-M-p"
                scite.MenuCommand(IDM_MATCHBRACE)
                return true
            end
        end

        if ctrl then
            if kc == 32 then --spc
                lastCmd = "C-spc"
                inRegion = true
                return true
            end

            if kc == 65 then --a
                lastCmd = "C-a"
                if inRegion then
                    editor:VCHomeExtend()
                else
                    editor:VCHome()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 66 then --b
                lastCmd = "C-b"
                if inRegion then
                    editor:CharLeftExtend()
                else
                    editor:CharLeft()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 68 then --d
                lastCmd = "C-d"
                if not inRegion then
                    editor:CharRightExtend()
                end
                editor:DeleteBack()
                inRegion = false
                return true
            end

            if kc == 69 then --e
                lastCmd = "C-e"
                if inRegion then
                    editor:LineEndExtend()
                else
                    editor:LineEnd()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 70 then --f
                lastCmd = "C-f"
                if inRegion then
                    editor:CharRightExtend()
                else
                    editor:CharRight()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 71 then --g
                lastCmd = "C-g"
                inRegion = false
                inCx = false
                inMx = false
                inSrch = false
                if editor:AutoCActive() then
                    editor:AutoCCancel()
                end
                killring_hide()

                local tmpPos = editor.CurrentPos
                editor:ClearSelections() --ClearSelections moves the carret pos to document top
                editor:GotoPos(tmpPos) --So we gotta reset the carret pos
                return true
            end

            if kc == 72 then --h
                lastCmd = "C-h"
                editor:DeleteBack()
                inRegion = false
                return true
            end

            if kc == 75 then --k
                lastCmd = "C-k"
                inRegion = false
                local oriPos = editor.CurrentPos
                editor:ClearSelections() --ClearSelections moves the carret pos to document top
                editor:GotoPos(oriPos) --So we gotta reset the carret pos
                editor:LineEndExtend()
                local newPos = editor.CurrentPos
                if oriPos == newPos then
                    editor:CharRight()
                    editor:DeleteBack()
                else
                    killring_push(editor:GetSelText())
                    editor:Cut()
                end
            end

            if kc == 76 then --l
                lastCmd = "C-l"
                local line = editor:LineFromPosition(editor.CurrentPos)
                local top = editor:DocLineFromVisible(editor.FirstVisibleLine)
                local middle = top + editor.LinesOnScreen / 2
                editor:LineScroll(0, line - middle)
                return true
            end

            if kc == 77 and not inMx then --m
                lastCmd = "C-m"
                if editor:CallTipActive() then
                  editor:AutoCComplete()
                else
                  editor:NewLine()
                end
                return true
            end

            if kc == 78 then --n
                lastCmd = "C-n"
                if inRegion then
                    editor:LineDownExtend()
                else
                    editor:LineDown()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 80 then --p
                lastCmd = "C-p"
                if inRegion then
                    editor:LineUpExtend()
                else
                    editor:LineUp()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 82 then --r
                lastCmd = "C-r"
                if inSrch then
                    scite.MenuCommand(IDM_FINDNEXTBACK)
                else
                    scite.MenuCommand(IDM_FIND)
                    inSrch = true
                end
                return true
            end

            if kc == 83 then --s
                lastCmd = "C-s"
                if inSrch then
                    local tmpPos = editor.CurrentPos
                    if lastSrchPos == tmpPos then
--~                         scite.MenuCommand(IDM_FIND)
                        searchWithClipBoard()
                        inSrch = false
                    else
                    scite.MenuCommand(IDM_FINDNEXT)
                        lastSrchPos = tmpPos
                    end
                else
--~                     scite.MenuCommand(IDM_FIND)
                    searchWithClipBoard()
                    lastSrchPos = editor.CurrentPos
                    inSrch = true
                end
                return true
            end

            if kc == 86 then --v
                lastCmd = "C-v"
                if inRegion then
                    editor:PageDownExtend()
                else
                    editor:PageDown()
                end
                return true
            end

            if kc == 87 then --w
                lastCmd = "C-w"
                killring_push(editor:GetSelText())
                editor:Cut()
                inRegion = false
                return true
            end

            if kc == 88 then --x
                lastCmd = "C-x"
                inCx = true
                return true
            end

            if kc == 89 then --y
                lastCmd = "C-y"
                killring_lastcpos = editor.CurrentPos
                editor:Paste()
                inRegion = false
                return true
            end

    --~         if kc == 191 then --/
            if kc == 47 then --/
                lastCmd = "C-/"
                editor:Undo()
                inRegion = false
                inCx = false
                inMx = false
                return true
            end
        end


        -- --------------------------------
        --M combination
        --
        if alt then
            if kc == 66 then --b
                lastCmd = "M-b"
                if inRegion then
                    editor:WordLeftExtend()
                else
                    editor:WordLeft()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 67 then --c
                lastCmd = "M-c"
                inRegion = false

                local tmpPos = editor.CurrentPos
                editor:ClearSelections() --ClearSelections moves the carret pos to document top
                editor:GotoPos(tmpPos) --So we gotta reset the carret pos

                editor:WordRightExtend()
                editor:LowerCase()
                editor:ClearSelections()
                editor:GotoPos(tmpPos)
                editor:CharRightExtend()
                editor:UpperCase()
                editor:ClearSelections()
                editor:GotoPos(tmpPos)
                return true
            end

            if kc == 70 then --f
                lastCmd = "M-f"
                if inRegion then
                    editor:WordRightExtend()
                else
                    editor:WordRight()
                end
                inSrch = false
                killring_hide()
                return true
            end

            if kc == 76 then --l
                lastCmd = "M-l"
                inRegion = false

                local tmpPos = editor.CurrentPos
                editor:ClearSelections() --ClearSelections moves the carret pos to document top
                editor:GotoPos(tmpPos) --So we gotta reset the carret pos

                editor:WordRightExtend()
                editor:LowerCase()
                editor:ClearSelections()
                editor:GotoPos(tmpPos)
                return true
            end

            if kc == 82 then --r
                lastCmd = "M-r"
                scite.MenuCommand(IDM_REPLACE)

                return true
            end

            if kc == 85 then --u
                lastCmd = "M-u"
                inRegion = false

                local tmpPos = editor.CurrentPos
                editor:ClearSelections() --ClearSelections moves the carret pos to document top
                editor:GotoPos(tmpPos) --So we gotta reset the carret pos

                editor:WordRightExtend()
                editor:UpperCase()
                editor:ClearSelections()
                editor:GotoPos(tmpPos)
                return true
            end

            if kc == 86 then --v
                lastCmd = "M-v"
                if inRegion then
                    editor:PageUpExtend()
                else
                    editor:PageUp()
                end
                return true
            end

            if kc == 87 then --w
                lastCmd = "M-w"
                killring_push(editor:GetSelText())
                editor:Copy()
                inRegion = false
                local tmpPos = editor.CurrentPos
                editor:ClearSelections() --ClearSelections moves the carret pos to document top
                editor:GotoPos(tmpPos) --So we gotta reset the carret pos
                return true
            end

            if kc == 88 then --x
                lastCmd = "M-x"
                output:DocumentEnd()
                output:InsertText(-1, LINEFEED .. "M-x ")
                output:DocumentEnd()
                mXBuffer = {}
                inMx = true
                return true
            end

            if kc == 89 then --y
                if (lastCmd == "C-y" or lastCmd == "M-y") then
                    lastCmd = "M-y"
                    local nextText = killring_shift()
                    if nextText ~= nil then
                        editor:Undo()
                        killring_show()
                        editor:InsertText(editor.CurrentPos, nextText)
                        editor:CopyText(nextText)
                        editor:GotoPos(editor.CurrentPos + #nextText)
                        return true
                    end
                end
                return true
            end

            if kc == 188 or kc == 60 then --,
                if shift then --<
                    lastCmd = "M-<"
                    if inRegion then
                        editor:DocumentStartExtend()
                    else
                        editor:DocumentStart()
                    end
                end
                return true
            end

            if kc == 190 or kc == 62 then --.
                if shift then -->
                    lastCmd = "M->"
                    if inRegion then
                        editor:DocumentEndExtend()
                    else
                        editor:DocumentEnd()
                    end
                end
                return true
            end

            if kc == 59 then --;
                lastCmd = "M-;"
                scite.MenuCommand(IDM_BLOCK_COMMENT)
                return true
            end

        end

        return false
    end
end

--add emacs to OnKey array
emacs = emacs()
addOnkey({
    label = "emacs",
    func = emacs
})
