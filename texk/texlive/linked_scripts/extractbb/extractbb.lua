#!/usr/bin/env texlua
-- extractbb-lua
-- https://github.com/gucci-on-fleek/extractbb
-- SPDX-License-Identifier: MPL-2.0+
-- SPDX-FileCopyrightText: 2024 Max Chernoff
--
-- A wrapper script to allow you to choose which implementation of extractbb to
-- use. Should hopefully be replaced with the ``scratch'' file in TeX Live 2025.
--
-- v1.0.5 (2024-11-21) %%version %%dashdate

---------------------
--- Configuration ---
---------------------
-- Choose which implementation of extractbb to use.
local DEFAULT = "wrapper"


-----------------
--- Execution ---
-----------------

-- Send the error messages to stderr.
local function error(...)
    -- Header
    io.stderr:write("! extractbb ERROR: ")

    -- Message
    for i = 1, select("#", ...) do
        io.stderr:write(tostring(select(i, ...)), " ")
    end

    -- Flush and exit
    io.stderr:flush()
    os.exit(1)
end

-- Get the value of the environment variable that decides which version to run.
local env_choice = os.env["TEXLIVE_EXTRACTBB"]

-- If the environment variable is set to a file path, run that directly.
local env_mode = lfs.attributes(env_choice or "", "mode")
if (env_mode == "file") or (env_mode == "link") then
    arg[0] = env_choice
    table.insert(arg, 1, env_choice)
    arg[-1] = nil
    return os.exec(arg)
end

-- Map the choice names to file names.
kpse.set_program_name("texlua", "extractbb")
local choice_mapping = {
    wrapper = kpse.find_file("extractbb-wrapper.lua", "lua", true),
    scratch = kpse.find_file("extractbb-scratch.lua", "lua", true),
}

-- Choose the implementation to run.
local choice = choice_mapping[env_choice] or choice_mapping[DEFAULT]

if not choice then
    error("No implementation of extractbb found.")
end

-- Make sure that the script is not writable.
if kpse.out_name_ok_silent_extended(choice) then
    if os.env["TEXLIVE_EXTRACTBB_UNSAFE"] == "unsafe" then
        -- If we're running in development mode, then we can allow this.
    else
        error("Refusing to run a writable script.")
    end
end

-- Make sure that the script is beside this one, just to be safe
local split_dir_pattern = "^(.*)[/\\]([^/\\]-)$"
local current_dir, current_name = arg[0]:match(split_dir_pattern)
local choice_dir, choice_name = choice:match(split_dir_pattern)

if current_dir ~= choice_dir then
    -- Resolve the symlinks and try again
    current_dir = lfs.symlinkattributes(current_dir, "target")
    choice_dir = lfs.symlinkattributes(choice_dir, "target")
    if current_dir ~= choice_dir then
        error("Refusing to run a script from a different directory.")
    end
end

-- And run it.
dofile(choice)
