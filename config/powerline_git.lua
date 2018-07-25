-- Constants
local branchSymbol = ""
local commitAheadSymbol = ""
local commitBehindSymbol = ""
local pushSymbol = ""
local segmentColors = {
    clean = {
        fill = colorGreen,
        text = colorWhite
    },
    dirty = {
        fill = colorYellow,
        text = colorBlack
    }
}
---
-- Check if string String starts with string Start
--
---
function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

---
-- Finds out the name of the current branch
-- @return {nil|git branch name}
---
function get_git_branch(git_dir)
    git_dir = git_dir or get_git_dir()

    -- If git directory not found then we're probably outside of repo
    -- or something went wrong. The same is when head_file is nil
    local head_file = git_dir and io.open(git_dir..'/HEAD')
    if not head_file then return end

    local HEAD = head_file:read()
    head_file:close()

    -- if HEAD matches branch expression, then we're on named branch
    -- otherwise it is a detached commit
    local branch_name = HEAD:match('ref: refs/heads/(.+)')

    return branch_name or 'HEAD detached at '..HEAD:sub(1, 7)
end

---
-- Gets the .git directory
-- copied from clink.lua
-- clink.lua is saved under %CMDER_ROOT%\vendor
-- @return {bool} indicating there's a git directory or not
---
function get_git_dir(path)

    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i-1)
        end
        return prefix
    end

    -- Checks if provided directory contains git directory
    local function has_git_dir(dir)
        return clink.is_dir(dir..'/.git') and dir..'/.git'
    end

    local function has_git_file(dir)
        local gitfile = io.open(dir..'/.git')
        if not gitfile then return false end

        local git_dir = gitfile:read():match('gitdir: (.*)')
        gitfile:close()

        return git_dir and dir..'/'..git_dir
    end

    -- Set default path to current directory
    if not path or path == '.' then path = clink.get_cwd() end

    -- Calculate parent path now otherwise we won't be
    -- able to do that inside of logical operator
    local parent_path = pathname(path)

    return has_git_dir(path)
        or has_git_file(path)
        -- Otherwise go up one level and make a recursive call
        or (parent_path ~= path and get_git_dir(parent_path) or nil)
end

---
-- Gets the status of working dir
-- @return {bool} indicating true for clean, false for dirty
---
function get_git_status()
    local file = io.popen("git --no-optional-locks status --porcelain 2>nul")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()
    return true
end

function get_git_origin()
    origin = ""
    local file = io.popen("git remote get-url origin")
    for line in file:lines() do
        if string.find(line, "bitbucket.org") then 
            origin = ""
        end
        if string.find(line, "github.com") then 
            origin = ""
        end
        file:close()
        return origin
    end
    return origin
end

function get_git_untracked_files_count()
    origin = 0
    local file = io.popen("git status --porcelain")
    for line in file:lines() do
        origin = origin + 1
        return origin
    end
    file:close()
    return origin
end

-- function get_git_current_commit_hash()
--     local hash = ""
--     local file = io.popen("git rev-parse HEAD")
--     for line in file:lines() do
--         hash = line
--         file:close()
--         return hash
--     end
--     return hash    
-- end

-- function get_git_current_upstream()
--     local upstream = ""
--     local file = io.popen("git rev-parse --symbolic-full-name --abbrev-ref @{upstream}")
--     for line in file:lines() do
--         if starts.with(line, "fatal") then
--             -- no upstream
--         else
--             upstream = line
--         end
--         file:close()
--         return false
--     end
--     return upstream    
-- end

-- function get_git_commits_ahead()
--     local hash = get_git_current_commit_hash()
--     local commits_ahead = 0
--     local upstream = get_git_current_upstream()
--     if upstream then
--         local file = io.popen("git log --pretty=oneline --topo-order --left-right "..hash.."..."..upstream)
--         for line in file:lines() do
--             if string.starts(line, "<") then
--                 commits_ahead = commits_ahead + 1
--             end
--         end
--         file:close()
--     end
--     return commits_ahead
-- end

-- function get_git_commits_behind()
--     local hash = get_git_current_commit_hash()
--     local upstream = get_git_current_upstream()
--     local commits_behind = 0
--     if upstream then
--         local file = io.popen("git log --pretty=oneline --topo-order --left-right "..hash.."..."..upstream)
--         for line in file:lines() do
--             if string.starts(line, ">") then
--                 commits_ahead = commits_ahead + 1
--             end
--         end
--         file:close()
--     end
--     return commits_behind
-- end

-- * Segment object with these properties:
---- * isNeeded: sepcifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segment = {
    isNeeded = false,
    text = "",
    textColor = 0,
    fillColor = 0
}

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
    segment.isNeeded = get_git_dir()
    if segment.isNeeded then
        -- if we're inside of git repo then try to detect current branch
        local branch = get_git_branch(git_dir)
        if branch then
            -- Has branch => therefore it is a git folder, now figure out status
            local gitStatus = get_git_status()
            local origin = get_git_origin()
            local untracked_files_count = get_git_untracked_files_count()
            -- local commits_ahead = get_git_commits_ahead()
            -- local commits_behind = get_git_commits_behind()
            -- local commit_difference = ""
            -- local push = ""
            -- if commits_ahead>0 or commits_behind> 0 then
            --     commit_difference = commits_behind..commitBehindSymbol..commits_ahead..commitAheadSymbol.." "
            -- end
            -- segment.text = " "..branchSymbol.." "..origin.." "..branch.." "..commit_difference
            segment.text = " "..branchSymbol.." "..origin.." "..branch
            if gitStatus then
                segment.textColor = segmentColors.clean.text
                segment.fillColor = segmentColors.clean.fill
            else
                segment.textColor = segmentColors.dirty.text
                segment.fillColor = segmentColors.dirty.fill
                segment.text = segment.text.." ±"..untracked_files_count
            end
        end
    end
end 

---
-- Uses the segment properties to add a new segment to the prompt
---
local function addAddonSegment()
    init()
    if segment.isNeeded then 
        addSegment(segment.text, segment.textColor, segment.fillColor)
    end 
end 

-- Register this addon with Clink
clink.prompt.register_filter(addAddonSegment, 60)