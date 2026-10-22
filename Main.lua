-- ============================================================
--   ██╗  ██╗ █████╗ ██╗     ██╗     ██╗███╗   ██╗██╗   ██╗
--   ██║ ██╔╝██╔══██╗██║     ██║     ██║████╗  ██║╚██╗ ██╔╝
--   █████╔╝ ███████║██║     ██║     ██║██╔██╗ ██║ ╚████╔╝
--   ██╔═██╗ ██╔══██║██║     ██║     ██║██║╚██╗██║  ╚██╔╝
--   ██║  ██╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║
--   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝
-- ============================================================
-- ===== ПОЛНАЯ LINUX-СИСТЕМА В 3D =====
-- ============================================================

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- ============================================================
-- ===== 1. ЦВЕТА (КЛАССИЧЕСКИЙ ТЕРМИНАЛ) =====
-- ============================================================
local colors = {
    bg = Color3.fromRGB(0, 0, 0),
    text = Color3.fromRGB(255, 255, 255),
    green = Color3.fromRGB(0, 255, 0),
    amber = Color3.fromRGB(255, 191, 0),
    red = Color3.fromRGB(255, 0, 0),
    cyan = Color3.fromRGB(0, 255, 255),
    purple = Color3.fromRGB(200, 100, 255),
    gray = Color3.fromRGB(150, 150, 150),
    darkgray = Color3.fromRGB(80, 80, 80),
}

-- ============================================================
-- ===== 2. ЯДРО (KERNEL) =====
-- ============================================================
local kernel = {
    name = "JCJ_KERNEL",
    version = "3.0.0",
    build = "2026.07.31",
    architecture = "x86_64",
    os = "RobloxOS",
    distro = "Outpost 3 Linux",
    hostname = "outpost3",
    user = "root",
    uptime = 0,
    processes = {},
    pid_counter = 100,
    modules = {
        ["nvme"] = {version = "1.2.3", status = "loaded"},
        ["usb"] = {version = "4.5.6", status = "loaded"},
        ["wifi"] = {version = "2.1.0", status = "active"},
        ["bluetooth"] = {version = "3.0.1", status = "active"},
        ["audio"] = {version = "5.1.2", status = "loaded"},
        ["gpu"] = {version = "6.0.0", status = "active"},
        ["network"] = {version = "4.3.2", status = "loaded"},
        ["storage"] = {version = "3.2.1", status = "active"},
        ["input"] = {version = "2.0.0", status = "loaded"},
        ["security"] = {version = "1.0.0", status = "active"},
    },
    drivers = {
        ["nvidia"] = {version = "535.154.05", status = "loaded"},
        ["amd"] = {version = "6.5.3", status = "inactive"},
        ["intel"] = {version = "2.1.0", status = "inactive"},
        ["realtek"] = {version = "1.0.0", status = "loaded"},
    }
}

-- ============================================================
-- ===== 3. ЗАГРУЗЧИК (BOOTLOADER) =====
-- ============================================================
local bootloader = {
    version = "2.0.0",
    timeout = 5,
    default_entry = 1,
    entries = {
        {name = "JCJ_KERNEL v3.0.0", description = "Outpost 3 Linux (x86_64)", kernel = "jcj_kernel"},
        {name = "JCJ_KERNEL (Recovery)", description = "Single-user mode", kernel = "jcj_kernel_recovery", recovery = true},
        {name = "Windows 11 Pro", description = "Windows 11 Pro (NTFS)", kernel = "windows", type = "ntfs"},
        {name = "Kali Linux 2026.1", description = "Kali Linux (live mode)", kernel = "kali_linux", type = "live"},
        {name = "Arch Linux", description = "Arch Linux (rolling release)", kernel = "arch_linux", type = "rolling"},
        {name = "Ubuntu 24.04 LTS", description = "Ubuntu LTS (stable)", kernel = "ubuntu", type = "lts"},
    }
}

-- ============================================================
-- ===== 4. ПОЛЬЗОВАТЕЛИ =====
-- ============================================================
local users = {
    {name = "root", uid = 0, gid = 0, home = "/root", shell = "/bin/bash", password = "toor", is_root = true, groups = {"root", "sudo", "admin", "wheel"}},
    {name = "Yahmyh78", uid = 1000, gid = 1000, home = "/home/Yahmyh78", shell = "/bin/zsh", password = "12345", is_root = false, groups = {"sudo", "users", "wheel"}},
    {name = "guest", uid = 1001, gid = 1001, home = "/home/guest", shell = "/bin/bash", password = "guest", is_root = false, groups = {"users"}},
}

local currentUser = users[2]
local isRoot = false
local lastSudoTime = 0

-- ============================================================
-- ===== 5. ФАЙЛОВАЯ СИСТЕМА =====
-- ============================================================
local fileSystem = {
    ["/"] = {
        type = "dir",
        children = {
            ["home"] = {type = "dir", children = {
                ["root"] = {type = "dir", children = {
                    ["Desktop"] = {type = "dir", children = {}},
                    ["Documents"] = {type = "dir", children = {
                        ["report.txt"] = {type = "file", content = "Outpost 3 Status: OPERATIONAL"},
                        ["hack.log"] = {type = "file", content = "[*] Hack initiated at " .. os.date("%Y-%m-%d %H:%M:%S")},
                    }},
                    ["Downloads"] = {type = "dir", children = {}},
                    [".bashrc"] = {type = "file", content = "alias ll='ls -la'\nalias la='ls -a'\nexport PS1='┌──(\\u@\\h)-[\\w]\\n└─$ '"},
                    [".zshrc"] = {type = "file", content = "PROMPT='[%n@%m %1~]$ '\nZSH_THEME='robbyrussell'"},
                    ["hack.sh"] = {type = "file", content = "#!/bin/bash\necho '🚀 Hacking the system...'\n./activate_console"},
                    ["outpost3.log"] = {type = "file", content = "[*] OUTPOST 3 CONNECTION LOG\n[+] Connection established at " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n[+] Solver protocol active"},
                    ["notes.txt"] = {type = "file", content = "Remember: With great power comes great responsibility."},
                }},
                ["Yahmyh78"] = {type = "dir", children = {
                    ["Desktop"] = {type = "dir", children = {}},
                    ["Documents"] = {type = "dir", children = {}},
                }},
            }},
            ["etc"] = {type = "dir", children = {
                ["hostname"] = {type = "file", content = "outpost3"},
                ["hosts"] = {type = "file", content = "127.0.0.1 localhost\n::1 localhost\n192.168.1.100 outpost3"},
                ["passwd"] = {type = "file", content = "root:x:0:0:root:/root:/bin/bash\nYahmyh78:x:1000:1000::/home/Yahmyh78:/bin/zsh"},
                ["shadow"] = {type = "file", content = "root:$6$xyz:19000:0:99999:7:::\nYahmyh78:$6$abc:19000:0:99999:7:::"},
                ["fstab"] = {type = "file", content = "/dev/sda1 / ext4 defaults 0 1\n/dev/sda2 swap swap defaults 0 0"},
                ["os-release"] = {type = "file", content = "NAME=\"Outpost 3 Linux\"\nVERSION=\"3.0.0\"\nID=outpost\nPRETTY_NAME=\"Outpost 3 Linux 3.0.0\""},
            }},
            ["usr"] = {type = "dir", children = {
                ["bin"] = {type = "dir", children = {
                    ["bash"] = {type = "file", content = "#!/bin/bash\necho 'Bash 5.2'"},
                    ["ls"] = {type = "file", content = "#!/bin/bash\necho 'Listing files...'"},
                    ["python"] = {type = "file", content = "#!/usr/bin/python3\nprint('Python 3.11')"},
                }},
                ["lib"] = {type = "dir", children = {}},
                ["share"] = {type = "dir", children = {}},
            }},
            ["tmp"] = {type = "dir", children = {}},
            ["var"] = {type = "dir", children = {
                ["log"] = {type = "dir", children = {
                    ["syslog"] = {type = "file", content = "[*] System log\n[+] Boot completed at " .. os.date("%Y-%m-%d %H:%M:%S")},
                }},
            }},
            ["sys"] = {type = "dir", children = {}},
            ["proc"] = {type = "dir", children = {}},
            ["boot"] = {type = "dir", children = {
                ["vmlinuz"] = {type = "file", content = "[KERNEL IMAGE] v" .. kernel.version},
                ["initrd.img"] = {type = "file", content = "[INITRD IMAGE]"},
                ["grub"] = {type = "dir", children = {
                    ["grub.cfg"] = {type = "file", content = "set default=0\nset timeout=5\nmenuentry 'Outpost 3 Linux' { linux /vmlinuz root=/dev/sda1 }"},
                }},
            }},
            ["mnt"] = {type = "dir", children = {}},
            ["opt"] = {type = "dir", children = {}},
            ["srv"] = {type = "dir", children = {}},
        }
    }
}

local currentPath = "/home/root"
local promptText = "┌──(root㉿outpost3)-[~]\n└─$ "

-- ============================================================
-- ===== 6. ФУНКЦИИ ФАЙЛОВОЙ СИСТЕМЫ =====
-- ============================================================
local function getPathObject(path)
    if path == "/" then return fileSystem["/"] end
    if path == "" then path = "/" end
    if path == "~" or path == "~/root" then path = "/home/root" end
    if path:sub(1, 1) ~= "/" then path = currentPath .. "/" .. path end
    local parts = {}
    for part in path:gmatch("[^/]+") do
        if part == ".." then table.remove(parts)
        elseif part ~= "." then table.insert(parts, part) end
    end
    if #parts == 0 then return fileSystem["/"] end
    local current = fileSystem["/"]
    for _, part in ipairs(parts) do
        if current.children and current.children[part] then
            current = current.children[part]
        else return nil end
    end
    return current
end

local function getFullPath() return currentPath end

local function formatBytes(bytes)
    if bytes > 1024*1024*1024 then return string.format("%.2f GB", bytes/1024/1024/1024)
    elseif bytes > 1024*1024 then return string.format("%.2f MB", bytes/1024/1024)
    elseif bytes > 1024 then return string.format("%.2f KB", bytes/1024)
    else return bytes .. " B" end
end

local function hasSudoAccess(user)
    for _, g in ipairs(user.groups or {}) do
        if g == "sudo" or g == "admin" then return true end
    end
    return user.is_root or false
end

local function checkRoot()
    if isRoot then return true end
    addTerminalLine("❌ Permission denied! Need root privileges.", colors.red)
    addTerminalLine("   Use 'sudo' or 'su root'", colors.gray)
    return false
end

-- ============================================================
-- ===== 7. УПРАВЛЕНИЕ ПРОЦЕССАМИ =====
-- ============================================================
local function createProcess(name, action)
    kernel.pid_counter = kernel.pid_counter + 1
    local pid = kernel.pid_counter
    table.insert(kernel.processes, {
        pid = pid, name = name, status = "running",
        action = action, start_time = os.time()
    })
    return pid
end

local function killProcess(pid)
    for i, proc in ipairs(kernel.processes) do
        if proc.pid == pid then
            proc.status = "terminated"
            table.remove(kernel.processes, i)
            addTerminalLine("✅ Process " .. pid .. " terminated", colors.green)
            return
        end
    end
    addTerminalLine("❌ Process " .. pid .. " not found", colors.red)
end

local function listProcesses()
    if #kernel.processes == 0 then
        addTerminalLine("📊 No running processes", colors.text)
        return
    end
    addTerminalLine("📊 PROCESS LIST:", colors.green)
    for _, proc in ipairs(kernel.processes) do
        local runtime = os.time() - proc.start_time
        local minutes = math.floor(runtime / 60)
        local seconds = runtime % 60
        addTerminalLine("  PID: " .. proc.pid .. " | " .. proc.name .. " | STATUS: " .. proc.status .. " | TIME: " .. minutes .. "m " .. seconds .. "s", colors.text)
    end
end

-- ============================================================
-- ===== 8. ПАНЕЛИ И ТЕРМИНАЛ =====
-- ============================================================
local panels = {}
local terminalPanels = {}
local monitorConnection = nil
local terminalLines = {}
local currentInput = ""
local maxLines = 14
local terminalActive = false

local fps = 0
local frameCount = 0
local lastFpsUpdate = tick()

-- Ждём загрузки персонажа
repeat task.wait(0.5) until player.Character and player.Character:FindFirstChild("HumanoidRootPart")

local hrp = player.Character.HumanoidRootPart
local hum = player.Character:FindFirstChildOfClass("Humanoid")

-- Очистка старых панелей
for _, obj in pairs(workspace:GetChildren()) do
    if obj:IsA("Part") and string.find(obj.Name, "MDPanel") then
        obj:Destroy()
    end
end

-- ============================================================
-- ===== 9. ФУНКЦИИ ТЕРМИНАЛА =====
-- ============================================================
function addTerminalLine(text, color)
    table.insert(terminalLines, {text = text, color = color or colors.text})
    if #terminalLines > maxLines then table.remove(terminalLines, 1) end
    updateTerminalDisplay()
end

function updateTerminalDisplay()
    for _, panel in ipairs(terminalPanels) do
        if panel and panel.Parent then
            for _, child in pairs(panel:GetChildren()) do
                if child:IsA("SurfaceGui") and child.Face == Enum.NormalId.Back then
                    for _, lbl in pairs(child:GetChildren()) do
                        if lbl:IsA("TextLabel") and lbl.Name == "TerminalOutput" then
                            local text = ""
                            for _, line in ipairs(terminalLines) do
                                text = text .. line.text .. "\n"
                            end
                            text = text .. promptText .. currentInput .. "█"
                            lbl.Text = text
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- ===== 10. ЗАГРУЗЧИК (ФУНКЦИИ) =====
-- ============================================================
function showBootloader()
    addTerminalLine("╔═══════════════════════════════════════════════════════════════╗", colors.green)
    addTerminalLine("║                                                               ║", colors.green)
    addTerminalLine("║   ██╗  ██╗ █████╗ ██╗     ██╗     ██╗███╗   ██╗██╗   ██╗     ║", colors.green)
    addTerminalLine("║   ██║ ██╔╝██╔══██╗██║     ██║     ██║████╗  ██║╚██╗ ██╔╝     ║", colors.green)
    addTerminalLine("║   █████╔╝ ███████║██║     ██║     ██║██╔██╗ ██║ ╚████╔╝      ║", colors.green)
    addTerminalLine("║   ██╔═██╗ ██╔══██║██║     ██║     ██║██║╚██╗██║  ╚██╔╝       ║", colors.green)
    addTerminalLine("║   ██║  ██╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║        ║", colors.green)
    addTerminalLine("║   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝        ║", colors.green)
    addTerminalLine("║                                                               ║", colors.green)
    addTerminalLine("║           JCJ_BOOTLOADER v" .. bootloader.version .. "               ║", colors.green)
    addTerminalLine("║           Build: " .. kernel.build .. "                        ║", colors.green)
    addTerminalLine("║                                                               ║", colors.green)
    addTerminalLine("╚═══════════════════════════════════════════════════════════════╝", colors.green)
    addTerminalLine("", colors.text)
    for i, entry in ipairs(bootloader.entries) do
        local marker = (i == bootloader.default_entry) and "▶" or " "
        local color = entry.recovery and colors.amber or colors.green
        addTerminalLine(marker .. " " .. i .. ". " .. entry.name, color)
        addTerminalLine("   " .. entry.description, colors.gray)
    end
    addTerminalLine("", colors.text)
    addTerminalLine("  Use 'boot_entry <number>' to select", colors.gray)
    if bootloader.timeout > 0 then
        addTerminalLine("  Auto-booting in " .. bootloader.timeout .. "s", colors.amber)
    end
end

function bootEntry(index)
    local entry = bootloader.entries[index]
    if not entry then addTerminalLine("❌ Invalid entry!", colors.red) return end
    addTerminalLine("", colors.text)
    addTerminalLine("⟳ Loading " .. entry.name .. "...", colors.green)
    task.wait(0.5)
    if entry.kernel == "windows" then
        addTerminalLine("[+] NTFS partition detected", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Loading Windows kernel...", colors.green)
        task.wait(0.3)
        addTerminalLine("[✓] Windows 11 booted successfully!", colors.green)
    elseif entry.kernel == "kali_linux" then
        addTerminalLine("[+] Loading Kali Linux live image...", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Booting from USB...", colors.green)
        task.wait(0.3)
        addTerminalLine("[✓] Kali Linux live booted!", colors.green)
    elseif entry.kernel == "arch_linux" then
        addTerminalLine("[+] Loading Arch Linux...", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Syncing pacman...", colors.green)
        task.wait(0.3)
        addTerminalLine("[✓] Arch Linux booted!", colors.green)
    elseif entry.kernel == "ubuntu" then
        addTerminalLine("[+] Loading Ubuntu LTS...", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Starting snap services...", colors.green)
        task.wait(0.3)
        addTerminalLine("[✓] Ubuntu 24.04 LTS booted!", colors.green)
    else
        addTerminalLine("[+] Loading kernel image...", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Loading initrd...", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Detecting hardware...", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Mounting root filesystem...", colors.green)
        task.wait(0.3)
        addTerminalLine("[+] Starting system services...", colors.green)
        task.wait(0.3)
        if entry.recovery then
            addTerminalLine("[✓] RECOVERY MODE: Single-user shell", colors.amber)
        else
            addTerminalLine("[✓] JCJ_KERNEL booted successfully!", colors.green)
        end
    end
end

-- ============================================================
-- ===== 11. ВСЕ КОМАНДЫ ТЕРМИНАЛА =====
-- ============================================================
local terminalCommands = {
    -- Базовые
    ["help"] = {
        desc = "Show all commands",
        action = function()
            addTerminalLine("📖 Available commands:", colors.green)
            local cmds = {}
            for cmd, data in pairs(terminalCommands) do
                table.insert(cmds, cmd)
            end
            table.sort(cmds)
            local line = ""
            for i, cmd in ipairs(cmds) do
                line = line .. cmd .. "  "
                if i % 4 == 0 then
                    addTerminalLine("  " .. line, colors.text)
                    line = ""
                end
            end
            if line ~= "" then addTerminalLine("  " .. line, colors.text) end
        end
    },
    ["pwd"] = {desc = "Print working directory", action = function() addTerminalLine("📁 " .. getFullPath(), colors.green) end},
    ["cd"] = {
        desc = "Change directory",
        action = function(args)
            if not args[2] or args[2] == "~" or args[2] == "~/root" then
                currentPath = "/home/root"
                addTerminalLine("📁 ~", colors.green)
                return
            end
            local target = getPathObject(args[2])
            if target and target.type == "dir" then
                if args[2]:sub(1, 1) == "/" then currentPath = args[2]
                else currentPath = currentPath .. "/" .. args[2] end
                addTerminalLine("📁 " .. getFullPath(), colors.green)
            else
                addTerminalLine("❌ No such directory", colors.red)
            end
        end
    },
    ["ls"] = {
        desc = "List directory contents",
        action = function()
            local target = getPathObject(getFullPath())
            if target and target.type == "dir" then
                local items =  {}
                for name, data in pairs(target.children or {}) do
                    local icon = data.type == "dir" and "📁" or "📄"
                    table.insert(items, icon .. " " .. name)
                end
                table.sort(items)
                addTerminalLine("📋 " .. getFullPath() .. ":", colors.green)
                for _, item in ipairs(items) do
                    addTerminalLine("  " .. item, colors.text)
                end
                if #items == 0 then addTerminalLine("  (empty)", colors.gray) end
            end
        end
    },
    ["mkdir"] = {
        desc = "Create directory",
        action = function(args)
            if not args[2] then addTerminalLine("❌ Usage: mkdir <name>", colors.red) return end
            local target = getPathObject(getFullPath())
            if target and target.children then
                if target.children[args[2]] then
                    addTerminalLine("❌ File exists", colors.red)
                else
                    target.children[args[2]] = {type = "dir", children = {}}
                    addTerminalLine("✅ Created: " .. args[2], colors.green)
                end
            end
        end
    },
     ["rmdir"] = {
        desc = "Remove empty directory",
        action = function(args)
            if not args[2] then addTerminalLine("❌ Usage: rmdir <name>", colors.red) return end
            local target = getPathObject(getFullPath())
            if target and target.children and target.children[args[2]] then
                if target.children[args[2]].type == "dir" and #target.children[args[2]].children == 0 then
                    target.children[args[2]] = nil
                    addTerminalLine("✅ Removed: " .. args[2], colors.green)
                else
                    addTerminalLine("❌ Directory not empty", colors.red)
                end
            else
                addTerminalLine("❌ No such directory", colors.red)
            end
        end
    },
    ["touch"] = {
        desc = "Create file",
        action = function(args)
            if not args[2] then addTerminalLine("❌ Usage: touch <name>", colors.red) return end
            local target = getPathObject(getFullPath())
            if target and target.children then
                target.children[args[2]] = {type = "file", content = ""}
                addTerminalLine("✅ Created: " .. args[2], colors.green)
            end
        end
    },
    ["rm"] = {
        desc = "Remove file",
        action = function(args)
            if not args[2] then addTerminalLine("❌ Usage: rm <name>", colors.red) return end
            local target = getPathObject(getFullPath())
            if target and target.children and target.children[args[2]] then
                if target.children[args[2]].type == "file" then
                    target.children[args[2]] = nil
                    addTerminalLine("✅ Removed: " .. args[2], colors.green)
                else
                    addTerminalLine("❌ Is a directory (use rmdir)", colors.red)
                end
            else
                addTerminalLine("❌ No such file", colors.red)
            end
        end
    },
    ["cat"] = {
        desc = "Read file",
        action = function(args)
            if not args[2] then addTerminalLine("❌ Usage: cat <file>", colors.red) return end
            local target = getPathObject(getFullPath())
            if target and target.children and target.children[args[2]] then
                if target.children[args[2]].type == "file" then
                    addTerminalLine("📄 " .. args[2] .. ":", colors.green)
                    addTerminalLine(target.children[args[2]].content or "(empty)", colors.text)
                else
                    addTerminalLine("❌ Is a directory", colors.red)
                end
            else
                addTerminalLine("❌ No such file", colors.red)
            end
        end
    },
     ["echo"] = {
        desc = "Display message",
        action = function(args)
            local msg = table.concat(args, " ", 2)
            addTerminalLine("💬 " .. msg, colors.text)
        end
    },
    ["clear"] = {
        desc = "Clear terminal",
        action = function()
            terminalLines = {}
            updateTerminalDisplay()
            addTerminalLine("🔄 Terminal cleared", colors.green)
        end
    },

    -- Пользователи и права
    ["whoami"] = {
        desc = "Show current user",
        action = function()
            local status = isRoot and " 👑 ROOT" or ""
            addTerminalLine("?? " .. currentUser.name .. status, colors.green)
        end
    },
    ["id"] = {
        desc = "Show user and group IDs",
        action = function()
            addTerminalLine("👤 uid=" .. currentUser.uid .. "(" .. currentUser.name .. ") gid=" .. currentUser.gid .. "(" .. currentUser.groups[1] .. ")", colors.green)
            addTerminalLine("   groups=" .. table.concat(currentUser.groups, ","), colors.text)
            if isRoot then addTerminalLine("   👑 ROOT PRIVILEGES", colors.amber) end
        end
    },
    ["su"] = {
        desc = "Switch user (su root)",
        action = function(args)
            local targetName = args[2] or "root"
            local targetUser = nil
            for _, u in ipairs(users) do
                if u.name == targetName then targetUser = u; break end
            end
            if not targetUser then
                addTerminalLine("❌ User not found: " .. targetName, colors.red)
                return
            end
            if targetUser.name == "root" then
                isRoot = true
                currentUser = targetUser
                promptText = "┌──(root㉿outpost3)-[~]\n└─$ "
                addTerminalLine("👑 You are now root!", colors.amber)
                updateTerminalDisplay()
            else
                currentUser = targetUser
                isRoot = false
                promptText = "┌──(" .. currentUser.name .. "㉿outpost3)-[~]\n└─$ "
                addTerminalLine("👤 Switched to: " .. targetUser.name, colors.green)
                updateTerminalDisplay()
            end
        end
    },
    ["sudo"] = {
        desc = "Execute as root",
        action = function(args)
            if not args[2] then
                addTerminalLine("❌ Usage: sudo <command>", colors.red)
                return
            end
            if not hasSudoAccess(currentUser) then
                addTerminalLine("❌ User " .. currentUser.name .. " is not in the sudoers file.", colors.red)
                addTerminalLine("   This incident will be reported.", colors.amber)
                return
            end
            if os.time() - lastSudoTime > 300 then
                addTerminalLine("🔐 [sudo] password for " .. currentUser.name .. ": ", colors.green)
                addTerminalLine("   (Password: toor)", colors.gray)
                lastSudoTime = os.time()
            end
            local oldUser = currentUser
            local oldRoot = isRoot
            isRoot = true
            currentUser = users[1]
            addTerminalLine("👑 Executing '" .. args[2] .. "' as root...", colors.amber)
            local cmd = args[2]
            local cmdArgs = {cmd}
            for i = 3, #args do table.insert(cmdArgs, args[i]) end
            if terminalCommands[cmd] then
                terminalCommands[cmd].action(cmdArgs)
            else
                addTerminalLine("❌ Command not found: " .. cmd, colors.red)
            end
            currentUser = oldUser
            isRoot = oldRoot
        end
    },
    ["passwd"] = {
        desc = "Change user password",
        action = function(args)
            local target = args[2] or currentUser.name
            local user = nil
            for _, u in ipairs(users) do
                if u.name == target then user = u; break end
            end
            if not user then
                addTerminalLine("❌ User not found: " .. target, colors.red)
                return
            end
            if user.name ~= currentUser.name and not isRoot then
                addTerminalLine("❌ Only root can change other users' passwords.", colors.red)
                return
            end
            addTerminalLine("🔐 Changing password for " .. user.name, colors.green)
            addTerminalLine("📌 New password: ******", colors.gray)
            addTerminalLine("✅ Password updated for " .. user.name, colors.green)
        end
    },
     ["useradd"] = {
        desc = "Add a new user (admin only)",
        action = function(args)
            if not checkRoot() then return end
            if not args[2] then
                addTerminalLine("❌ Usage: useradd <username>", colors.red)
                return
            end
            local newUser = {
                name = args[2],
                uid = 2000 + #users,
                gid = 100,
                home = "/home/" .. args[2],
                shell = "/bin/bash",
                password = "password",
                is_root = false,
                groups = {"users"}
            }
            table.insert(users, newUser)
            addTerminalLine("✅ User created: " .. newUser.name, colors.green)
            addTerminalLine("   UID: " .. newUser.uid, colors.text)
            addTerminalLine("   Home: " .. newUser.home, colors.text)
            addTerminalLine("   Groups: users", colors.text)
        end
    },
    ["userdel"] = {
        desc = "Delete a user (admin only)",
        action = function(args)
            if not checkRoot() then return end
            if not args[2] then
                addTerminalLine("❌ Usage: userdel <username>", colors.red)
                return
            end
            if args[2] == "root" then
                addTerminalLine("❌ Cannot delete root user!", colors.red)
                return
            end
            for i, u in ipairs(users) do
                if u.name == args[2] then
                    table.remove(users, i)
                    addTerminalLine("✅ User deleted: " .. args[2], colors.green)
                    return
                end
            end
            addTerminalLine("❌ User not found: " .. args[2], colors.red)
        end
    },
    ["groups"] = {
        desc = "Show user groups",
        action = function(args)
            local target = args[2] or currentUser.name
            local user = nil
            for _, u in ipairs(users) do
                if u.name == target then user = u; break end
            end
            if not user then
                addTerminalLine("❌ User not found: " .. target, colors.red)
                return
            end
            addTerminalLine("👤 " .. target .. ":", colors.green)
            for _, group in ipairs(user.groups or {}) do
                addTerminalLine("   " .. group, colors.text)
            end
        end
    },
    ["who"] = {
        desc = "Show logged in users",
        action = function()
            addTerminalLine("👤 LOGGED IN USERS:", colors.green)
            addTerminalLine("  root     tty1  " .. os.date("%Y-%m-%d %H:%M"), colors.text)
            addTerminalLine("  " .. currentUser.name .. "  pts/0  " .. os.date("%Y-%m-%d %H:%M"), colors.text)
            for _, u in ipairs(users) do
                if u.name ~= "root" and u.name ~= currentUser.name then
                    addTerminalLine("  " .. u.name .. "  pts/" .. math.random(1,5) .. "  " .. os.date("%Y-%m-%d %H:%M"), colors.text)
                end
            end
        end
    },
    ["adduser_sudo"] = {
        desc = "Add user to sudo (admin only)",
        action = function(args)
            if not checkRoot() then return end
            if not args[2] then
                addTerminalLine("❌ Usage: adduser_sudo <username>", colors.red)
                return
            end
            local user = nil
            for _, u in ipairs(users) do
                if u.name == args[2] then user = u; break end
            end
            if not user then
                addTerminalLine("❌ User not found: " .. args[2], colors.red)
                return
            end
            if not table.find(user.groups, "sudo") then
                table.insert(user.groups, "sudo")
                addTerminalLine("✅ User " .. user.name .. " added to sudo group", colors.green)
            else
                addTerminalLine("ℹ️ User already in sudo group", colors.amber)
            end
        end
    },
    ["deluser_sudo"] = {
        desc = "Remove from sudo (admin only)",
        action = function(args)
            if not checkRoot() then return end
            if not args[2] then
                addTerminalLine("❌ Usage: deluser_sudo <username>", colors.red)
                return
            end
            local user = nil
            for _, u in ipairs(users) do
                if u.name == args[2] then user = u; break end
            end
            if not user then
                addTerminalLine("❌ User not found: " .. args[2], colors.red)
                return
            end
            for i, g in ipairs(user.groups) do
                if g == "sudo" then
                    table.remove(user.groups, i)
                    addTerminalLine("✅ User " .. user.name .. " removed from sudo", colors.green)
                    return
                end
            end
            addTerminalLine("ℹ️ User not in sudo group", colors.amber)
        end
    },
     ["list_users"] = {
        desc = "List all users",
        action = function()
            addTerminalLine("👥 ALL USERS:", colors.green)
            for _, u in ipairs(users) do
                local status = u.is_root and " 👑" or ""
                local sudo = table.find(u.groups, "sudo") and " (sudo)" or ""
                addTerminalLine("  " .. u.name .. status .. sudo .. " (UID: " .. u.uid .. ")", colors.text)
            end
        end
    },

    -- Системные
    ["uptime"] = {
        desc = "Show uptime",
        action = function()
            local uptime = math.floor(os.time() / 3600)
            local hours = uptime % 24
            local days = math.floor(uptime / 24)
            addTerminalLine("⏱️ Uptime: " .. days .. "d " .. hours .. "h " .. math.floor(os.time() % 3600 / 60) .. "m", colors.green)
        end
    },
    ["kernel"] = {
        desc = "Show kernel info",
        action = function()
            addTerminalLine("🧠 JCJ_KERNEL v" .. kernel.version, colors.green)
            addTerminalLine("  Build: " .. kernel.build, colors.text)
            addTerminalLine("  Arch: " .. kernel.architecture, colors.text)
            addTerminalLine("  OS: " .. kernel.os, colors.text)
            addTerminalLine("  Distro: " .. kernel.distro, colors.text)
            addTerminalLine("  Hostname: " .. kernel.hostname, colors.text)
            addTerminalLine("  Processes: " .. #kernel.processes, colors.text)
        end
    },
    ["ps"] = {
        desc = "List processes",
        action = function() listProcesses() end
    },
    ["kill"] = {
        desc = "Kill process (kill <PID>)",
        action = function(args)
            if args[2] then
                local pid = tonumber(args[2])
                if pid then killProcess(pid)
                else addTerminalLine("❌ Invalid PID", colors.red) end
            else
                addTerminalLine("❌ Usage: kill <PID>", colors.red)
            end
        end
    },
    ["neofetch"] = {
        desc = "System info with logo",
        action = function()
            addTerminalLine("🐧", colors.green)
            addTerminalLine("OS: " .. kernel.os .. " " .. kernel.version, colors.text)
            addTerminalLine("Host: Outpost 3", colors.text)
            addTerminalLine("Kernel: " .. kernel.version .. "-jcj", colors.text)
            addTerminalLine("Uptime: 3d 14h 22m", colors.text)
            addTerminalLine("Shell: zsh 5.9", colors.text)
            addTerminalLine("CPU: AMD Ryzen 9 7950X", colors.text)
            addTerminalLine("GPU: NVIDIA RTX 4090", colors.text)
            addTerminalLine("Memory: 8192MiB / 16384MiB", colors.text)
            addTerminalLine("DE: JCJ_DE 1.0", colors.text)
            addTerminalLine("Theme: Murder Drones", colors.text)
        end
    },
    ["dmesg"] = {
        desc = "Show kernel messages",
        action = function()
            addTerminalLine("📋 KERNEL MESSAGES:", colors.green)
            addTerminalLine("[    0.000] Linux version " .. kernel.version .. "-jcj (gcc-13)", colors.text)
            addTerminalLine("[    0.123] CPU: AMD Ryzen 9 7950X (16 cores, 32 threads)", colors.text)
            addTerminalLine("[    0.456] RAM: 16384MB available", colors.text)
            addTerminalLine("[    0.789] GPU: NVIDIA RTX 4090 detected", colors.text)
            addTerminalLine("[    1.012] NVMe: 1TB SSD detected", colors.text)
            addTerminalLine("[    1.345] USB: 4 ports detected", colors.text)
            addTerminalLine("[    1.678] Network: eth0 UP (1000Mbps)", colors.text)
            addTerminalLine("[    2.000] Wi-Fi: wlan0 UP", colors.text)
            addTerminalLine("[    2.345] Bluetooth: hci0 UP", colors.text)
            addTerminalLine("[    2.678] Audio: Realtek ALC1220 detected", colors.text)
            addTerminalLine("[    3.000] Input: Keyboard and Mouse detected", colors.text)
            addTerminalLine("[    3.456] Security: SELinux enabled", colors.text)
            addTerminalLine("[    4.000] System ready", colors.green)
        end
    },
     ["date"] = {
        desc = "Show date and time",
        action = function()
            addTerminalLine("📅 " .. os.date("%A, %B %d, %Y %H:%M:%S"), colors.green)
        end
    },
    ["cal"] = {
        desc = "Show calendar",
        action = function()
            local d = os.date("*t")
            addTerminalLine("📅 " .. os.date("%B %Y"), colors.green)
            addTerminalLine("  Mo Tu We Th Fr Sa Su", colors.text)
            addTerminalLine("     1  2  3  4  5  6", colors.text)
            addTerminalLine("  7  8  9 10 11 12 13", colors.text)
            addTerminalLine(" 14 15 16 17 18 19 20", colors.text)
            addTerminalLine(" 21 22 23 24 25 26 27", colors.text)
            addTerminalLine(" 28 29 30 31", colors.text)
        end
    },
    ["history"] = {
        desc = "Command history",
        action = function()
            addTerminalLine("📜 COMMAND HISTORY:", colors.green)
            addTerminalLine("  1  help", colors.text)
            addTerminalLine("  2  ls", colors.text)
            addTerminalLine("  3  cd /home", colors.text)
            addTerminalLine("  4  pwd", colors.text)
            addTerminalLine("  5  cat .bashrc", colors.text)
            addTerminalLine("  6  neofetch", colors.text)
            addTerminalLine("  7  clear", colors.text)
        end
    },

    -- Сеть
    ["ifconfig"] = {
        desc = "Show network interfaces",
        action = function()
            addTerminalLine("📡 NETWORK INTERFACES:", colors.green)
            addTerminalLine("  eth0: flags=4163<UP,BROADCAST,RUNNING>  mtu 1500", colors.text)
            addTerminalLine("    inet 192.168.1.100  netmask 255.255.255.0  broadcast 192.168.1.255", colors.gray)
            addTerminalLine("    ether 00:1A:2B:3C:4D:5E  txqueuelen 1000", colors.gray)
            addTerminalLine("    RX packets 1234567  bytes 2.3 GB", colors.gray)
            addTerminalLine("    TX packets 987654  bytes 1.8 GB", colors.gray)
            addTerminalLine("", colors.text)
            addTerminalLine("  lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536", colors.text)
            addTerminalLine("    inet 127.0.0.1  netmask 255.0.0.0", colors.gray)
        end
    },
     ["ping"] = {
        desc = "Ping a host",
        action = function(args)
            local host = args[2] or "localhost"
            local dns = {
                ["localhost"] = "127.0.0.1",
                ["google.com"] = "142.250.185.78",
                ["github.com"] = "140.82.121.3",
                ["outpost3"] = "192.168.1.100",
                ["roblox.com"] = "128.116.126.118"
            }
            local ip = dns[host] or "0.0.0.0"
            addTerminalLine("📶 PING " .. host .. " (" .. ip .. "):", colors.green)
            for i = 1, 4 do
                local loss = math.random(0, 1)
                if loss == 0 then
                    addTerminalLine("  64 bytes from " .. ip .. ": icmp_seq=" .. i .. " ttl=64 time=" .. math.random(10, 50) .. "ms", colors.green)
                else
                    addTerminalLine("  Request timeout for icmp_seq " .. i, colors.amber)
                end
                task.wait(0.3)
            end
            addTerminalLine("--- " .. host .. " ping statistics ---", colors.text)
            addTerminalLine("  4 packets transmitted, 3 received, 25% packet loss", colors.text)
        end
    },
    ["netstat"] = {
        desc = "Show network connections",
        action = function()
            addTerminalLine("🌐 ACTIVE CONNECTIONS:", colors.green)
            addTerminalLine("  Proto  Local Address          Foreign Address        State", colors.text)
            addTerminalLine("  TCP    192.168.1.100:22       192.168.1.50:54321     ESTABLISHED", colors.gray)
            addTerminalLine("  TCP    192.168.1.100:443      192.168.1.60:12345     ESTABLISHED", colors.gray)
            addTerminalLine("  TCP    192.168.1.100:80       192.168.1.70:67890     TIME_WAIT", colors.gray)
            addTerminalLine("  UDP    192.168.1.100:53       8.8.8.8:53             ESTABLISHED", colors.gray)
            addTerminalLine("  SSH    192.168.1.100:22       192.168.1.80:98765     ESTABLISHED", colors.gray)
        end
    },
    ["nslookup"] = {
        desc = "DNS lookup",
        action = function(args)
            local host = args[2] or "localhost"
            local dns = {
                ["localhost"] = "127.0.0.1",
                ["google.com"] = "142.250.185.78",
                ["github.com"] = "140.82.121.3",
                ["outpost3"] = "192.168.1.100",
                ["roblox.com"] = "128.116.126.118"
            }
            local ip = dns[host] or "Unknown"
            if ip ~= "Unknown" then
                addTerminalLine("🔍 DNS RESOLUTION:", colors.green)
                addTerminalLine("  Name:    " .. host, colors.text)
                addTerminalLine("  Address: " .. ip, colors.text)
                addTerminalLine("  TTL:     3600", colors.text)
            else
                addTerminalLine("❌ Host not found", colors.red)
            end
        end
    },
     
     -- Ядро и модули
    ["lsmod"] = {
        desc = "Show loaded kernel modules",
        action = function()
            addTerminalLine("📦 LOADED KERNEL MODULES:", colors.green)
            addTerminalLine("  Module      Version  Status", colors.text)
            for name, data in pairs(kernel.modules) do
                local color = data.status == "active" and colors.green or colors.amber
                addTerminalLine("  " .. string.upper(name) .. string.rep(" ", 12 - #name) .. data.version .. string.rep(" ", 10 - #data.version) .. data.status, color)
            end
        end
    },
    ["modprobe"] = {
        desc = "Load kernel module",
        action = function(args)
            if not checkRoot() then return end
            if not args[2] then
                addTerminalLine("❌ Usage: modprobe <module>", colors.red)
                return
            end
            if kernel.modules[args[2]] then
                kernel.modules[args[2]].status = "loaded"
                addTerminalLine("✅ Module " .. args[2] .. " loaded", colors.green)
            else
                addTerminalLine("❌ Module not found: " .. args[2], colors.red)
            end
        end
    },
    ["rmmod"] = {
        desc = "Remove kernel module",
        action = function(args)
            if not checkRoot() then return end
            if not args[2] then
                addTerminalLine("❌ Usage: rmmod <module>", colors.red)
                return
            end
            if kernel.modules[args[2]] then
                kernel.modules[args[2]].status = "unloaded"
                addTerminalLine("✅ Module " .. args[2] .. " removed", colors.green)
            else
                addTerminalLine("❌ Module not found: " .. args[2], colors.red)
            end
        end
    },
    ["modinfo"] = {
        desc = "Show module information",
        action = function(args)
            if not args[2] then
                addTerminalLine("❌ Usage: modinfo <module>", colors.red)
                return
            end
            local mod = kernel.modules[args[2]]
            if mod then
                addTerminalLine("📦 MODULE: " .. string.upper(args[2]), colors.green)
                addTerminalLine("  Version: " .. mod.version, colors.text)
                addTerminalLine("  Status: " .. mod.status, colors.text)
                addTerminalLine("  Path: /lib/modules/" .. kernel.version .. "/kernel/drivers/" .. args[2] .. ".ko", colors.text)
            else
                addTerminalLine("❌ Module not found", colors.red)
            end
        end
    },
     
     -- Загрузчик
    ["reboot"] = {
        desc = "Reboot system",
        action = function()
            addTerminalLine("🔄 Rebooting system...", colors.amber)
            task.wait(0.5)
            terminalLines = {}
            showBootloader()
            addTerminalLine("", colors.text)
            addTerminalLine("📌 Select OS to boot:", colors.green)
        end
    },
    ["shutdown"] = {
        desc = "Shutdown system",
        action = function()
            addTerminalLine("⏹️ Shutting down system...", colors.amber)
            task.wait(0.5)
            addTerminalLine("[✓] System powered off!", colors.green)
            terminalActive = false
        end
    },
    ["boot"] = {
        desc = "Show bootloader menu",
        action = function()
            terminalLines = {}
            showBootloader()
            bootloader.timeout = 0
        end
    },
    ["menu"] = {
        desc = "Open bootloader menu",
        action = function()
            terminalLines = {}
            showBootloader()
            bootloader.timeout = 0
        end
    },
    ["bootloader"] = {
        desc = "Show bootloader info",
        action = function()
            addTerminalLine("🌀 JCJ_BOOTLOADER v" .. bootloader.version, colors.green)
            addTerminalLine("  Timeout: " .. bootloader.timeout .. "s", colors.text)
            addTerminalLine("  Default: " .. bootloader.entries[bootloader.default_entry].name, colors.text)
            addTerminalLine("  Entries: " .. #bootloader.entries, colors.text)
        end
    },
    ["boot_entry"] = {
        desc = "Boot specific entry (boot_entry 1)",
        action = function(args)
            if args[2] then
                local num = tonumber(args[2])
                if num and num >= 1 and num <= #bootloader.entries then
                    bootEntry(num)
                else
                    addTerminalLine("❌ Invalid entry. Available: 1-" .. #bootloader.entries, colors.red)
                end
            else
                addTerminalLine("❌ Usage: boot_entry <number>", colors.red)
            end
        end
    },

     -- Пакетные менеджеры
    ["apt"] = {
        desc = "APT package manager (Debian/Ubuntu)",
        action = function(args)
            if not args[2] then
                addTerminalLine("📦 APT Package Manager", colors.green)
                addTerminalLine("Commands: update, upgrade, install, remove, list, search", colors.text)
                return
            end
            local cmd = args[2]
            if cmd == "update" then
                addTerminalLine("[+] Updating package list...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] Package list updated (2476 packages)", colors.green)
            elseif cmd == "upgrade" then
                addTerminalLine("[+] Upgrading packages...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] 0 upgraded, 0 newly installed", colors.green)
            elseif cmd == "install" then
                local pkg = args[3] or "unknown"
                addTerminalLine("[+] Installing " .. pkg .. "...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] " .. pkg .. " installed", colors.green)
            elseif cmd == "remove" then
                local pkg = args[3] or "unknown"
                addTerminalLine("[+] Removing " .. pkg .. "...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] " .. pkg .. " removed", colors.green)
            elseif cmd == "list" then
                addTerminalLine("📦 Installed packages:", colors.green)
                addTerminalLine("  jcj_kernel 3.0.0", colors.text)
                addTerminalLine("  murder_drones 2.0.0", colors.text)
                addTerminalLine("  robux 1.0.0", colors.text)
            elseif cmd == "search" then
                local query = args[3] or ""
                addTerminalLine("🔍 Searching for: " .. query, colors.green)
                addTerminalLine("  jcj_kernel  - JCJ Kernel", colors.text)
                addTerminalLine("  hack_tools  - Hacking Tools", colors.text)
            end
        end
    },
    ["pacman"] = {
        desc = "pacman package manager (Arch)",
        action = function(args)
            if not args[2] then
                addTerminalLine("📦 PACMAN (Arch)", colors.green)
                addTerminalLine("Commands: -S, -R, -Q, -Sy", colors.text)
                return
            end
            local cmd = args[2]
            if cmd == "-S" then
                local pkg = args[3] or "unknown"
                addTerminalLine("[+] Installing " .. pkg .. " from AUR...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] " .. pkg .. " installed", colors.green)
            elseif cmd == "-R" then
                local pkg = args[3] or "unknown"
                addTerminalLine("[+] Removing " .. pkg .. "...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] " .. pkg .. " removed", colors.green)
            elseif cmd == "-Q" then
                addTerminalLine("📦 Installed packages:", colors.green)
                addTerminalLine("  jcj_kernel 3.0.0", colors.text)
                addTerminalLine("  murder_drones 2.0.0", colors.text)
            elseif cmd == "-Sy" then
                addTerminalLine("[+] Syncing package database...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] Database updated", colors.green)
            end
        end
    },

     -- Развлечения
    ["fortune"] = {
        desc = "Random quote",
        action = function()
            local quotes = {
                "The best way to predict the future is to create it.",
                "Hack the planet!",
                "With great power comes great responsibility.",
                "The only way to do great work is to love what you do.",
                "Stay hungry, stay foolish.",
                "The code is strong with this one.",
                "Hello, World!",
                "This is the way.",
                "In the middle of difficulty lies opportunity.",
                "To be or not to be, that is the question."
            }
            addTerminalLine("🔮 " .. quotes[math.random(#quotes)], colors.green)
        end
    },
    ["cmatrix"] = {
        desc = "Matrix rain effect",
        action = function()
            addTerminalLine("🟢 MATRIX RAIN", colors.green)
            for i = 1, 10 do
                local line = ""
                for j = 1, 40 do
                    line = line .. (math.random() > 0.3 and string.char(math.random(65, 90)) or " ")
                end
                addTerminalLine(line, colors.green)
                task.wait(0.05)
            end
            addTerminalLine("🟢 Matrix rain stopped.", colors.green)
        end
    },
    ["cowsay"] = {
        desc = "Cow says message",
        action = function(args)
            local msg = table.concat(args, " ", 2) or "Moo!"
            addTerminalLine(" _________________ ", colors.green)
            addTerminalLine("< " .. msg .. " >", colors.green)
            addTerminalLine(" ----------------- ", colors.green)
            addTerminalLine("        \\   ^__^", colors.green)
            addTerminalLine("         \\  (oo)\\_______", colors.green)
            addTerminalLine("            (__)\\       )\\/\\", colors.green)
            addTerminalLine("                ||----w |", colors.green)
            addTerminalLine("                ||     ||", colors.green)
        end
    },
    ["sl"] = {
        desc = "Steam locomotive 🚂",
        action = function()
            addTerminalLine("  🚂 CHOO CHOO!", colors.amber)
            addTerminalLine("     ________", colors.amber)
            addTerminalLine("    /        \\", colors.amber)
            addTerminalLine("   /  ______  \\", colors.amber)
            addTerminalLine("  /  /      \\  \\", colors.amber)
            addTerminalLine("  |  |  🚂  |  |", colors.amber)
            addTerminalLine("  |  |______|  |", colors.amber)
            addTerminalLine("  |___________|", colors.amber)
        end
    },
    ["yes"] = {
        desc = "Print 'yes' forever",
        action = function()
            addTerminalLine("⚠️ Press Ctrl+C to stop", colors.amber)
            for i = 1, 10 do
                addTerminalLine("yes", colors.text)
                task.wait(0.1)
            end
            addTerminalLine("✅ Stopped after 10 lines", colors.green)
        end
    },

     -- Программирование
    ["lua"] = {
        desc = "Lua interpreter",
        action = function(args)
            local code = table.concat(args, " ", 2)
            if code == "" then
                addTerminalLine("💻 Lua 5.4", colors.green)
                addTerminalLine("  Type 'lua <code>' to execute", colors.text)
                return
            end
            local success, result = pcall(loadstring(code))
            if success then
                addTerminalLine("  " .. tostring(result), colors.green)
            else
                addTerminalLine("❌ Error: " .. result, colors.red)
            end
        end
    },
    ["python"] = {
        desc = "Python interpreter",
        action = function(args)
            local code = table.concat(args, " ", 2)
            if code == "" then
                addTerminalLine("🐍 Python 3.11", colors.green)
                addTerminalLine("  Type 'python <code>' to execute", colors.text)
                return
            end
            addTerminalLine("  " .. code .. " -> Hello from Python!", colors.green)
        end
    },
    ["bash"] = {
        desc = "Bash shell",
        action = function(args)
            local code = table.concat(args, " ", 2)
            if code == "" then
                addTerminalLine("💻 Bash 5.2", colors.green)
                addTerminalLine("  Type 'bash <command>' to execute", colors.text)
                return
            end
            addTerminalLine("  $ " .. code, colors.text)
            addTerminalLine("  Hello from Bash!", colors.green)
        end
    },

     -- Графический интерфейс
    ["startx"] = {
        desc = "Start X11 graphical interface",
        action = function()
            addTerminalLine("🖥️ Starting X11 graphical interface...", colors.green)
            task.wait(0.5)
            addTerminalLine("✅ X11 started!", colors.green)
            addTerminalLine("  Click desktop icons to open apps", colors.text)
            addTerminalLine("  Close window to return to terminal", colors.text)
        end
    },
    ["wayland"] = {
        desc = "Start Wayland compositor",
        action = function()
            addTerminalLine("🖥️ Starting Wayland compositor...", colors.green)
            task.wait(0.5)
            addTerminalLine("✅ Wayland started! (Faster and more secure)", colors.green)
        end
    },

    -- Безопасность
    ["security"] = {
        desc = "Show security status",
        action = function()
            addTerminalLine("🔒 SECURITY STATUS:", colors.green)
            addTerminalLine("  Firewall: 🟢 ACTIVE", colors.green)
            addTerminalLine("  SELinux: 🟢 ENFORCING", colors.green)
            addTerminalLine("  AppArmor: 🟢 LOADED", colors.green)
            addTerminalLine("  Security Updates: 🟢 INSTALLED", colors.green)
            addTerminalLine("  Root Access: " .. (isRoot and "🔴 ACTIVE" or "🟢 RESTRICTED"), isRoot and colors.red or colors.green)
            local sudoCount = 0
            for _, u in ipairs(users) do
                if table.find(u.groups, "sudo") then sudoCount = sudoCount + 1 end
            end
            addTerminalLine("  Sudo Users: " .. sudoCount .. " users have sudo access", colors.text)
        end
    },
    ["exit"] = {
        desc = "Exit terminal",
        action = function()
            terminalActive = false
            addTerminalLine("🖥️ Terminal closed", colors.gray)
            updateTerminalDisplay()
        end
    },
}

-- ============================================================
-- ===== 12. СОЗДАНИЕ 3D ПАНЕЛЕЙ =====
-- ============================================================
local function createPanel(name, offset, logo, info)
    local panel = Instance.new("Part")
    panel.Name = name
    panel.Size = Vector3.new(6.5, 4.5, 0.1)
    panel.Color = colors.bg
    panel.Material = Enum.Material.SmoothPlastic
    panel.Transparency = 0
    panel.CanCollide = false
    panel.Anchored = false
    panel.Parent = hrp
    panel.CFrame = hrp.CFrame * offset

    local highlight = Instance.new("Highlight", panel)
    highlight.FillColor = colors.green
    highlight.FillTransparency = 0.9
    highlight.OutlineColor = colors.green
    highlight.OutlineTransparency = 0.2

    Instance.new("WeldConstraint", panel).Part0, panel.Part1 = panel, hrp


  -- Передняя сторона
    local fg = Instance.new("SurfaceGui", panel)
    fg.Face = Enum.NormalId.Front
    fg.AlwaysOnTop = true
    fg.CanvasSize = Vector2.new(650, 450)
    fg.BackgroundColor3 = colors.bg

    local logoL = Instance.new("TextLabel", fg)
    logoL.Size = UDim2.new(1, 0, 0.2, 0)
    logoL.BackgroundTransparency = 1
    logoL.TextColor3 = colors.green
    logoL.Font = Enum.Font.GothamBold
    logoL.TextSize = 24
    logoL.Text = logo
    logoL.TextXAlignment = Enum.TextXAlignment.Center

    local infoL = Instance.new("TextLabel", fg)
    infoL.Size = UDim2.new(0.95, 0, 0.75, 0)
    infoL.Position = UDim2.new(0.025, 0, 0.22, 0)
    infoL.BackgroundTransparency = 1
    infoL.TextColor3 = colors.text
    infoL.Font = Enum.Font.Code
    infoL.TextSize = 11
    infoL.Text = info
    infoL.TextXAlignment = Enum.TextXAlignment.Left
    infoL.TextYAlignment = Enum.TextYAlignment.Top
    infoL.TextWrapped = true

    -- Задняя сторона (терминал)
    local bg = Instance.new("SurfaceGui", panel)
    bg.Face = Enum.NormalId.Back
    bg.AlwaysOnTop = true
    bg.CanvasSize = Vector2.new(600, 400)
    bg.BackgroundColor3 = colors.bg

    local hdr = Instance.new("TextLabel", bg)
    hdr.Size = UDim2.new(1, 0, 0.06, 0)
    hdr.BackgroundTransparency = 1
    hdr.TextColor3 = colors.green
    hdr.Font = Enum.Font.Code
    hdr.TextSize = 11
    hdr.Text = "╔══ TERMINAL ═══════════════════════════════════════════════════╗"
    hdr.TextXAlignment = Enum.TextXAlignment.Left

    local out = Instance.new("TextLabel", bg)
    out.Name = "TerminalOutput"
    out.Size = UDim2.new(0.95, 0, 0.86, 0)
    out.Position = UDim2.new(0.025, 0, 0.07, 0)
    out.BackgroundTransparency = 1
    out.TextColor3 = colors.text
    out.Font = Enum.Font.Code
    out.TextSize = 11
    out.TextWrapped = true
    out.TextYAlignment = Enum.TextYAlignment.Top
    out.TextXAlignment = Enum.TextXAlignment.Left
    out.Text = ""

    local ftr = Instance.new("TextLabel", bg)
    ftr.Size = UDim2.new(1, 0, 0.04, 0)
    ftr.Position = UDim2.new(0, 0, 0.96, 0)
    ftr.BackgroundTransparency = 1
    ftr.TextColor3 = colors.green
    ftr.Font = Enum.Font.Code
    ftr.TextSize = 11
    ftr.Text = "╚════════════════════════════════════════════════════════════════╝"
    ftr.TextXAlignment = Enum.TextXAlignment.Left

    table.insert(terminalPanels, panel)
    table.insert(panels, {panel = panel, info = infoL})
    return infoL
end


-- Логотипы
local l1 = [[
██╗  ██╗ █████╗ ██╗     ██╗     ██╗███╗   ██╗██╗   ██╗
██║ ██╔╝██╔══██╗██║     ██║     ██║████╗  ██║╚██╗ ██╔╝
█████╔╝ ███████║██║     ██║     ██║██╔██╗ ██║ ╚████╔╝
██╔═██╗ ██╔══██║██║     ██║     ██║██║╚██╗██║  ╚██╔╝
██║  ██╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝
]]

local l2 = [[
█████╗ ██████╗  ██████╗██╗  ██╗
██╔══██╗██╔══██╗██╔════╝██║  ██║
███████║██████╔╝██║     ███████║
██╔══██║██╔══██╗██║     ██╔══██║
██║  ██║██║  ██║╚██████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
]]

local l3 = [[
██████╗ ██╗      █████╗  ██████╗██╗  ██╗
██╔══██╗██║     ██╔══██╗██╔════╝██║  ██║
██████╔╝██║     ███████║██║     ███████║
██╔══██╗██║     ██╔══██║██║     ██╔══██║
██████╔╝███████╗██║  ██║╚██████╗██║  ██║
╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
]]


-- Создание панелей
local i1 = createPanel("MDPanel_Kali", CFrame.new(-7.0, 2.0, -5.0) * CFrame.Angles(0, math.rad(25), 0), "🦞 KALI LINUX", l1 .. "\n\n[STATUS]: LOADING...")
local i2 = createPanel("MDPanel_Arch", CFrame.new(0, 2.0, -6.0) * CFrame.Angles(0, math.rad(180), 0), "🐧 ARCH LINUX", l2 .. "\n\n[STATUS]: LOADING...")
local i3 = createPanel("MDPanel_BlackArch", CFrame.new(7.0, 2.0, -5.0) * CFrame.Angles(0, math.rad(-25), 0), "💀 BLACKARCH", l3 .. "\n\n[STATUS]: LOADING...")


-- ============================================================
-- ===== 13. МОНИТОРИНГ =====
-- ============================================================
monitorConnection = runService.Heartbeat:Connect(function()
    if not hrp or not hrp.Parent then return end

    frameCount = frameCount + 1
    if tick() - lastFpsUpdate >= 1 then
        fps = frameCount
        frameCount = 0
        lastFpsUpdate = tick()
    end

    local time = os.date("%H:%M:%S")
    local health = hum and math.floor(hum.Health) or 0
    local maxHealth = hum and hum.MaxHealth or 100
    local players = #game.Players:GetPlayers()
    local pos = hrp.Position
    local x, y, z = math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z)

    if i1 and i1.Parent then
        i1.Text = l1 .. string.format([[
[STATUS]: ACTIVE
[TIME]: %s
[FPS]: %d
[PLAYERS]: %d
[HP]: %d/%d
]], time, fps, players, health, maxHealth)
    end

    if i2 and i2.Parent then
        i2.Text = l2 .. string.format([[
[STATUS]: ACTIVE
[POS]: %d %d %d
[FLY]: %s
[GOD]: %s
]], x, y, z,
    (rawget(_G, "_flyActive") and "🟢 ON" or "🔴 OFF"),
    (rawget(_G, "_godActive") and "🟢 ON" or "🔴 OFF"))
    end

    if i3 and i3.Parent then
        i3.Text = l3 .. string.format([[
[STATUS]: ACTIVE
[NOCLIP]: %s
[INVIS]: %s
[SPEED]: x%d
]],
    (rawget(_G, "_noclipActive") and "🟢 ON" or "🔴 OFF"),
    (rawget(_G, "_invisActive") and "🟢 ON" or "🔴 OFF"),
    rawget(_G, "_speedMultiplier") or 1)
    end
end)


-- ============================================================
-- ===== 14. ОБРАБОТКА ТЕРМИНАЛА =====
-- ============================================================
uis.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.Tab then
        terminalActive = not terminalActive
        if terminalActive then
            addTerminalLine("─" .. string.rep("─", 50), colors.gray)
            addTerminalLine("🖥️ TERMINAL ACTIVATED", colors.green)
            addTerminalLine("Type 'help' for commands, Tab to exit", colors.gray)
            addTerminalLine("─" .. string.rep("─", 50), colors.gray)
        end
        return
    end

    if not terminalActive then return end

    if input.KeyCode == Enum.KeyCode.Backspace then
        currentInput = currentInput:sub(1, -2)
        updateTerminalDisplay()
    elseif input.KeyCode == Enum.KeyCode.Return then
        if currentInput ~= "" then
            addTerminalLine(promptText .. currentInput, colors.text)
            local args = {}
            for word in currentInput:gmatch("%S+") do table.insert(args, word) end
            if #args > 0 then
                local cmd = args[1]:lower()
                if terminalCommands[cmd] then
                    terminalCommands[cmd].action(args)
                else
                    addTerminalLine("❌ Command not found: " .. cmd, colors.red)
                end
            end
            currentInput = ""
        end
        updateTerminalDisplay()
    elseif input.KeyCode == Enum.KeyCode.Space then
        currentInput = currentInput .. " "
        updateTerminalDisplay()
    else
        local char = input.KeyCode.Name
        if #char == 1 and (char:match("%a") or char:match("%d") or char == "-" or char == "_" or char == "." or char == "/") then
            local isShift = uis:IsKeyDown(Enum.KeyCode.LeftShift) or uis:IsKeyDown(Enum.KeyCode.RightShift)
            currentInput = currentInput .. (isShift and char:upper() or char:lower())
            updateTerminalDisplay()
        end
    end
end)


-- ============================================================
-- ===== 15. ГОРЯЧИЕ КЛАВИШИ =====
-- ============================================================
_G._flyActive = false
_G._godActive = false
_G._noclipActive = false
_G._invisActive = false
_G._speedMultiplier = 1

uis.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode

    if k == Enum.KeyCode.F then
        _G._flyActive = not _G._flyActive
        if _G._flyActive then
            hum.PlatformStand = true
            addTerminalLine("🕊️ Fly ON", colors.green)
        else
            hum.PlatformStand = false
            addTerminalLine("🕊️ Fly OFF", colors.red)
        end
    elseif k == Enum.KeyCode.G then
        _G._godActive = not _G._godActive
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not _G._godActive)
        hum.BreakJointsOnDeath = not _G._godActive
        addTerminalLine(_G._godActive and "🛡️ God ON" or "🛡️ God OFF", colors.amber)
    elseif k == Enum.KeyCode.N then
        _G._noclipActive = not _G._noclipActive
        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = not _G._noclipActive
            end
        end
        addTerminalLine(_G._noclipActive and "🧱 Noclip ON" or "🧱 Noclip OFF", colors.purple)
    elseif k == Enum.KeyCode.I then
        _G._invisActive = not _G._invisActive
        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("BasePart") then
                v.Transparency = _G._invisActive and 1 or 0
            end
        end
        addTerminalLine(_G._invisActive and "👁️ Invisible ON" or "👁️ Invisible OFF", colors.gray)
    elseif k == Enum.KeyCode.S and uis:IsKeyDown(Enum.KeyCode.LeftShift) then
        _G._speedMultiplier = _G._speedMultiplier == 1 and 2 or 1
        hum.WalkSpeed = 16 * _G._speedMultiplier
        addTerminalLine("🏃 Speed x" .. _G._speedMultiplier, colors.green)
    elseif k == Enum.KeyCode.H then
        hum.Health = hum.MaxHealth
        addTerminalLine("❤️ Healed!", colors.red)
    elseif k == Enum.KeyCode.Escape then
        for _, p in ipairs(panels) do
            p.panel.Transparency = p.panel.Transparency == 0 and 1 or 0
        end
    end
end)


-- ============================================================
-- ===== 16. ПРИВЕТСТВИЕ =====
-- ============================================================
task.wait(0.5)
addTerminalLine("╔══════════════════════════════════════════════════════╗", colors.green)
addTerminalLine("║  🦞 OUTPOST 3 LINUX v3.0                            ║", colors.green)
addTerminalLine("║  Kernel: JCJ_KERNEL " .. kernel.version .. "        ║", colors.green)
addTerminalLine("║  Bootloader: JCJ_BOOTLOADER v" .. bootloader.version .. "     ║", colors.green)
addTerminalLine("║  Press TAB to open terminal                       ║", colors.green)
addTerminalLine("║  Type 'help' for commands, 'menu' for bootloader ║", colors.green)
addTerminalLine("║  Hotkeys: F-G-N-I, Shift+S, H, ESC              ║", colors.green)
addTerminalLine("╚══════════════════════════════════════════════════════╝", colors.green)

print("🦞 OUTPOST 3 LINUX v3.0 FULL LOADED!")
print("HOTKEYS:")
print("  TAB - Open Terminal")
print("  F - Fly | G - God | N - Noclip")
print("  I - Invisible | Shift+S - Speed")
print("  H - Heal | ESC - Hide/Show")
