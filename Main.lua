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

-- Предварительные объявления: функции ниже больше не становятся глобальными,
-- а terminalCommands виден внутри help/sudo (раньше там был nil)
local addTerminalLine, updateTerminalDisplay, showBootloader, bootEntry
local setTerminalActive
local terminalCommands

-- Состояние эффектов (раньше хранилось в _G)
local state = {fly = false, god = false, noclip = false, invis = false, speed = 1}

-- Общие переменные новых подсистем (объявлены заранее, определяются ниже)
local captureBuffer = nil        -- не nil => вывод команды копится здесь (пайпы и перенаправление >)
local stdinLines = nil           -- ввод для команды, стоящей после "|"
local interruptFlag = false      -- Ctrl+C / Enter во время работы команды
local renderSuspended = false    -- пакетное обновление терминала (top, watch, редактор)
local pendingPrompt = nil        -- {label=, masked=} пока команда ждёт ввода (пароль, редактор)
local inputEvent = Instance.new("BindableEvent")
local env = {}                   -- переменные окружения
local aliases = {}               -- алиасы команд
local sshStack = {}              -- стек ssh-сессий
local bootTime = os.time()
local scrollOffset = 0           -- прокрутка терминала (PageUp/PageDown)
local bootToken, autoBootActive = 0, false
local currentThemeName = "classic"
local desktopGui                 -- ScreenGui рабочего стола (startx)
local executeLine, readLine, applyTheme, saveState, loadState, openDesktop, closeDesktop

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


-- Темы оформления (команда `theme`); classic совпадает с исходными цветами
local themes = {
    classic = {
        text = colors.text, green = colors.green, amber = colors.amber, red = colors.red,
        cyan = colors.cyan, purple = colors.purple, gray = colors.gray, darkgray = colors.darkgray,
    },
    amber = {
        text = Color3.fromRGB(255, 205, 120), green = Color3.fromRGB(255, 176, 0), amber = Color3.fromRGB(255, 120, 0),
        red = Color3.fromRGB(255, 70, 60), cyan = Color3.fromRGB(255, 225, 160), purple = Color3.fromRGB(255, 150, 100),
        gray = Color3.fromRGB(160, 135, 95), darkgray = Color3.fromRGB(90, 75, 50),
    },
    cyberpunk = {
        text = Color3.fromRGB(225, 225, 255), green = Color3.fromRGB(255, 0, 170), amber = Color3.fromRGB(255, 235, 0),
        red = Color3.fromRGB(255, 60, 90), cyan = Color3.fromRGB(0, 240, 255), purple = Color3.fromRGB(160, 80, 255),
        gray = Color3.fromRGB(140, 130, 175), darkgray = Color3.fromRGB(70, 60, 100),
    },
    ice = {
        text = Color3.fromRGB(235, 250, 255), green = Color3.fromRGB(120, 220, 255), amber = Color3.fromRGB(255, 220, 120),
        red = Color3.fromRGB(255, 110, 130), cyan = Color3.fromRGB(165, 255, 255), purple = Color3.fromRGB(190, 160, 255),
        gray = Color3.fromRGB(150, 170, 190), darkgray = Color3.fromRGB(80, 95, 110),
    },
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
local currentHost = "outpost3"   -- имя текущей машины (меняется при ssh)

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

local currentPath = "/home/Yahmyh78"

-- ===== Домашние папки, приглашение, права и владельцы =====
local function homeOf(user)
    -- в этой файловой системе домашняя папка root лежит в /home/root
    if user.name == "root" then return "/home/root" end
    return user.home
end

local function getPrompt()
    local cwd = currentPath
    local home = homeOf(currentUser)
    if cwd == home then
        cwd = "~"
    elseif cwd:sub(1, #home + 1) == home .. "/" then
        cwd = "~" .. cwd:sub(#home + 1)
    end
    return "┌──(" .. currentUser.name .. "㉿" .. currentHost .. ")-[" .. cwd .. "]\n└─" .. (isRoot and "#" or "$") .. " "
end

-- owner/mode хранятся в узлах; по умолчанию владелец root, режим 755 для папок и 644 для файлов
local function nodeOwner(node) return node.owner or "root" end
local function nodeMode(node) return node.mode or (node.type == "dir" and "755" or "644") end

local function chownTree(node, owner)
    node.owner = owner
    if node.children then
        for _, child in pairs(node.children) do chownTree(child, owner) end
    end
end

-- perm: "r" | "w" | "x"; root может всё
local function hasPerm(node, perm)
    if isRoot then return true end
    local mode = nodeMode(node)
    local digit
    if nodeOwner(node) == currentUser.name then
        digit = tonumber(mode:sub(1, 1))
    else
        digit = tonumber(mode:sub(3, 3))
        for _, group in ipairs(currentUser.groups or {}) do
            if group == nodeOwner(node) then
                digit = tonumber(mode:sub(2, 2))
                break
            end
        end
    end
    local bit = ({r = 4, w = 2, x = 1})[perm]
    return math.floor((digit or 0) / bit) % 2 == 1
end

do
    local rootNode = fileSystem["/"]
    local home = rootNode.children.home
    chownTree(home.children.Yahmyh78, "Yahmyh78")
    home.children.guest = {type = "dir", children = {}, owner = "guest"}
    home.children.root.mode = "700"
    home.children.root.children["hack.sh"].mode = "755"
    rootNode.children.etc.children.shadow.mode = "640"
    rootNode.children.tmp.mode = "777"
end

-- ===== Удалённые машины для ssh =====
local function makeUser(name, uid, password, groups, rootUser)
    return {
        name = name, uid = uid, gid = uid, home = rootUser and "/home/root" or ("/home/" .. name),
        shell = "/bin/bash", password = password, is_root = rootUser or false, groups = groups,
    }
end

local function buildRemoteFs(host, distro, userNames, notes)
    local home = {
        root = {type = "dir", owner = "root", mode = "700", children = {
            ["flag.txt"] = {type = "file", owner = "root", mode = "600", content = "FLAG{" .. host .. "_root_pwned}"},
        }},
    }
    for _, name in ipairs(userNames) do
        home[name] = {type = "dir", owner = name, children = {
            ["notes.txt"] = {type = "file", owner = name, content = notes[name] or "Nothing here."},
        }}
    end
    return {["/"] = {type = "dir", children = {
        home = {type = "dir", children = home},
        etc = {type = "dir", children = {
            hostname = {type = "file", content = host},
            ["os-release"] = {type = "file", content = 'NAME="' .. distro .. '"'},
        }},
        tmp = {type = "dir", mode = "777", children = {}},
        usr = {type = "dir", children = {bin = {type = "dir", children = {}}}},
        var = {type = "dir", children = {log = {type = "dir", children = {
            syslog = {type = "file", content = "[*] " .. host .. " boot completed"},
        }}}},
    }}}
end

local function buildMachine(host, ip, distro, rootPassword, accounts, notes)
    local list = {makeUser("root", 0, rootPassword, {"root", "sudo"}, true)}
    local names = {}
    local uid = 1000
    for _, acc in ipairs(accounts) do
        table.insert(list, makeUser(acc[1], uid, acc[2], {"sudo", "users"}))
        table.insert(names, acc[1])
        uid = uid + 1
    end
    return {ip = ip, distro = distro, users = list, fs = buildRemoteFs(host, distro, names, notes)}
end

local machines = {
    kali = buildMachine("kali", "192.168.1.101", "Kali Linux 2026.1", "kali",
        {{"pentester", "hunter2"}}, {pentester = "TODO: change the root password (it's still the distro name)."}),
    arch = buildMachine("arch", "192.168.1.102", "Arch Linux", "arch",
        {{"archer", "btw"}}, {archer = "I use Arch, btw."}),
    blackarch = buildMachine("blackarch", "192.168.1.103", "BlackArch Linux", "blackarch",
        {{"ghost", "boo"}}, {ghost = "Nothing to see here. (root has a flag.txt...)"}),
}

-- ============================================================
-- ===== 6. ФУНКЦИИ ФАЙЛОВОЙ СИСТЕМЫ =====
-- ============================================================
local function resolvePath(path)
    path = path or ""
    if path == "" or path == "~" then
        path = homeOf(currentUser)
    elseif path:sub(1, 2) == "~/" then
        path = homeOf(currentUser) .. "/" .. path:sub(3)
    elseif path:sub(1, 1) ~= "/" then
        path = currentPath .. "/" .. path
    end
    local parts = {}
    for part in path:gmatch("[^/]+") do
        if part == ".." then table.remove(parts)
        elseif part ~= "." then table.insert(parts, part) end
    end
    return "/" .. table.concat(parts, "/")
end

-- Возвращает узел, либо nil, "denied" если нет права x на одну из папок пути
local function getPathObject(path)
    local current = fileSystem["/"]
    for part in resolvePath(path):gmatch("[^/]+") do
        if current.type ~= "dir" or not current.children[part] then return nil end
        if not hasPerm(current, "x") then return nil, "denied" end
        current = current.children[part]
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
-- ===== 7. ПРОЦЕССЫ =====
-- ============================================================
local function createProcess(name, action, system)
    kernel.pid_counter = kernel.pid_counter + 1
    local proc = {
        pid = kernel.pid_counter,
        name = name,
        status = "running",
        alive = true,                -- фоновые команды проверяют этот флаг и завершаются после kill
        action = action,
        start_time = os.time(),
        system = system or false,
        user = system and "root" or currentUser.name,
    }
    table.insert(kernel.processes, proc)
    return proc.pid, proc
end

local function killProcess(pid)
    for i, proc in ipairs(kernel.processes) do
        if proc.pid == pid then
            if proc.system then
                addTerminalLine("❌ kill: (" .. pid .. ") - Operation not permitted", colors.red)
                return
            end
            if proc.user ~= currentUser.name and not isRoot then
                addTerminalLine("❌ kill: (" .. pid .. ") - Permission denied", colors.red)
                return
            end
            proc.status = "terminated"
            proc.alive = false
            table.remove(kernel.processes, i)
            addTerminalLine("✅ Process " .. pid .. " terminated", colors.green)
            return
        end
    end
    addTerminalLine("❌ Process " .. pid .. " not found", colors.red)
end

local function listProcesses()
    if not captureBuffer then
        addTerminalLine("  PID USER       TIME   STATUS    COMMAND", colors.green)
    end
    for _, proc in ipairs(kernel.processes) do
        local runtime = os.time() - proc.start_time
        addTerminalLine(string.format("%5d %-10s %02d:%02d  %-9s %s", proc.pid, proc.user or "root",
            math.floor(runtime / 60), runtime % 60, proc.status, proc.name), colors.text)
    end
end

-- ============================================================
-- ===== 8. ПАНЕЛИ И ТЕРМИНАЛ =====
-- ============================================================
local panels = {}
local monitorConnection = nil
local terminalLines = {}
local currentInput = ""
local maxLines = 22
local terminalActive = false

local fps = 0
local frameCount = 0
local lastFpsUpdate = tick()

local terminalLabels = {}   -- кэш лейблов терминала (заполняется в createPanel)
local commandHistory = {}
local historyIndex = 1
local busy = false

-- Персонаж и GUI (заполняются в setupCharacter / разделе 14)
local hrp, hum, baseWalkSpeed
local i1, i2, i3
local panelFolder
local screenGui, inputBox

-- ============================================================
-- ===== 9. ФУНКЦИИ ТЕРМИНАЛА (с историей прокрутки и RichText) =====
-- ============================================================
local MAX_SCROLLBACK = 500

local function escapeRich(s)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    return s
end

-- Возвращает добавленную строку (чтобы её можно было обновлять, например таймер автозагрузки)
function addTerminalLine(text, color)
    text = tostring(text)
    if captureBuffer then
        for line in (text .. "\n"):gmatch("(.-)\n") do
            table.insert(captureBuffer, line)
        end
        return nil
    end
    local last
    for line in (text .. "\n"):gmatch("(.-)\n") do
        last = {text = line, color = color or colors.text}
        table.insert(terminalLines, last)
        if #terminalLines > MAX_SCROLLBACK then table.remove(terminalLines, 1) end
    end
    updateTerminalDisplay()
    return last
end

function updateTerminalDisplay()
    if renderSuspended then return end
    local total = #terminalLines
    scrollOffset = math.clamp(scrollOffset, 0, math.max(0, total - maxLines))
    local first = math.max(1, total - maxLines + 1 - scrollOffset)
    local last = math.min(total, first + maxLines - 1)

    local parts = {}
    for i = first, last do
        local line = terminalLines[i]
        parts[#parts + 1] = string.format('<font color="#%s">%s</font>', line.color:ToHex(), escapeRich(line.text))
    end
    if scrollOffset > 0 then
        parts[#parts + 1] = string.format('<font color="#%s">  ↓ %d more line(s) below — PageDown / End</font>',
            colors.gray:ToHex(), scrollOffset)
    else
        local label, shown = getPrompt(), currentInput
        if pendingPrompt then
            label = pendingPrompt.label
            if pendingPrompt.masked then shown = string.rep("*", #currentInput) end
        end
        parts[#parts + 1] = string.format('<font color="#%s">%s</font>', colors.text:ToHex(), escapeRich(label .. shown .. "█"))
    end

    local text = table.concat(parts, "\n")
    for i = #terminalLabels, 1, -1 do
        local lbl = terminalLabels[i]
        if lbl.Parent then
            lbl.Text = text
        else
            table.remove(terminalLabels, i)
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
terminalCommands = {
    -- Базовые
    ["clear"] = {
        desc = "Clear terminal",
        action = function()
            terminalLines = {}
            updateTerminalDisplay()
            addTerminalLine("🔄 Terminal cleared", colors.green)
        end
    },

    -- Пользователи и права
    ["id"] = {
        desc = "Show user and group IDs",
        action = function()
            addTerminalLine("👤 uid=" .. currentUser.uid .. "(" .. currentUser.name .. ") gid=" .. currentUser.gid .. "(" .. currentUser.groups[1] .. ")", colors.green)
            addTerminalLine("   groups=" .. table.concat(currentUser.groups, ","), colors.text)
            if isRoot then addTerminalLine("   👑 ROOT PRIVILEGES", colors.amber) end
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
            local msg = table.concat(args, " ", 2)
            if msg == "" then msg = "Moo!" end
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
            local okLoad, fn, compileErr = pcall(loadstring, code)
            if not okLoad then
                addTerminalLine("❌ loadstring недоступен в этом окружении", colors.red)
                return
            end
            if not fn then
                addTerminalLine("❌ " .. tostring(compileErr), colors.red)
                return
            end
            local success, result = pcall(fn)
            if success then
                addTerminalLine("  " .. tostring(result), colors.green)
            else
                addTerminalLine("❌ Error: " .. tostring(result), colors.red)
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

     -- Графический интерфейс

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
}

-- ============================================================
-- ===== 11b. ИСПОЛНИТЕЛЬ КОМАНД: ПАЙПЫ, ПЕРЕНАПРАВЛЕНИЕ, ФОН, АЛИАСЫ =====
-- ============================================================
local function trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

-- украшения (заголовки, иконки) не попадают в пайпы и файлы
local function decor(text, color)
    if not captureBuffer then addTerminalLine(text, color) end
end

local function usage(name)
    local entry = terminalCommands[name]
    addTerminalLine("❌ Usage: " .. ((entry and entry.usage) or name), colors.red)
end

local function sortedKeys(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

-- Ввод строки от пользователя (пароли, редактор). nil = отмена (Tab / Ctrl+C)
readLine = function(label, masked)
    pendingPrompt = {label = label, masked = masked}
    currentInput = ""
    updateTerminalDisplay()
    local line = inputEvent.Event:Wait()
    pendingPrompt = nil
    currentInput = ""
    if line ~= nil then
        addTerminalLine(label .. (masked and string.rep("*", #line) or line), colors.text)
    end
    updateTerminalDisplay()
    return line
end

local function askPassword(user, label)
    for attempt = 1, 3 do
        local pw = readLine(label, true)
        if pw == nil then
            addTerminalLine("^C", colors.gray)
            return false
        end
        if pw == user.password then return true end
        addTerminalLine("Sorry, try again.", colors.red)
        if attempt == 2 then
            addTerminalLine("   (hint: starts with '" .. user.password:sub(1, 1) .. "', " .. #user.password .. " chars)", colors.gray)
        end
    end
    addTerminalLine("3 incorrect password attempts", colors.red)
    return false
end

-- Остановка: для фоновых команд флаг proc.alive, для обычных — Ctrl+C / Enter
local function stopRequested(ctx)
    if ctx and ctx.proc then return not ctx.proc.alive end
    return interruptFlag
end

local function uptimeString()
    local secs = os.time() - bootTime
    local hours = math.floor(secs / 3600)
    local mins = math.floor(secs % 3600 / 60)
    if hours > 0 then return string.format("%d h %d min", hours, mins) end
    return string.format("%d min %d s", mins, secs % 60)
end

local function getPingMs()
    local ok, value = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and math.floor(value) or nil
end

local function getMemoryMb()
    local ok, value = pcall(function()
        return game:GetService("Stats"):GetTotalMemoryUsageMb()
    end)
    return ok and math.floor(value) or nil
end

-- ---------- разбор строки ----------
local function expandVars(text)
    return (text:gsub("%$([%a_][%w_]*)", function(name)
        local dyn = {
            USER = currentUser.name, HOME = homeOf(currentUser), PWD = currentPath,
            HOSTNAME = currentHost, SHELL = currentUser.shell, UID = tostring(currentUser.uid),
        }
        return dyn[name] or env[name] or ""
    end))
end

local function tokenize(line)
    local tokens = {}
    local i, n = 1, #line
    while i <= n do
        if line:sub(i, i):match("%s") then
            i = i + 1
        else
            local tok, quote = "", nil
            while i <= n do
                local c = line:sub(i, i)
                if quote then
                    if c == quote then quote = nil else tok = tok .. c end
                elseif c == '"' or c == "'" then
                    quote = c
                elseif c:match("%s") then
                    break
                else
                    tok = tok .. c
                end
                i = i + 1
            end
            table.insert(tokens, tok)
        end
    end
    return tokens
end

-- делит строку по символу sep вне кавычек
local function splitUnquoted(line, sep)
    local parts, cur, quote = {}, "", nil
    for i = 1, #line do
        local c = line:sub(i, i)
        if quote then
            cur = cur .. c
            if c == quote then quote = nil end
        elseif c == '"' or c == "'" then
            quote = c
            cur = cur .. c
        elseif c == sep then
            table.insert(parts, cur)
            cur = ""
        else
            cur = cur .. c
        end
    end
    table.insert(parts, cur)
    return parts
end

-- ищет > или >> вне кавычек; возвращает команду, режим и файл
local function splitRedirect(seg)
    local quote = nil
    for i = 1, #seg do
        local c = seg:sub(i, i)
        if quote then
            if c == quote then quote = nil end
        elseif c == '"' or c == "'" then
            quote = c
        elseif c == ">" then
            local mode, nextPos = ">", i + 1
            if seg:sub(i + 1, i + 1) == ">" then
                mode, nextPos = ">>", i + 2
            end
            return seg:sub(1, i - 1), mode, trim(seg:sub(nextPos)):match("^(%S+)")
        end
    end
    return seg, nil, nil
end

-- ---------- помощники файловой системы ----------
local function splitParent(path)
    local resolved = resolvePath(path)
    if resolved == "/" then return nil, nil, resolved end
    local parentPath, name = resolved:match("^(.*)/([^/]+)$")
    if parentPath == "" then parentPath = "/" end
    return (getPathObject(parentPath)), name, resolved
end

local function newNode(kind, content)
    if kind == "dir" then
        return {type = "dir", children = {}, owner = currentUser.name, mode = "755"}
    end
    return {type = "file", content = content or "", owner = currentUser.name, mode = "644"}
end

local function contentLines(node)
    local lines = {}
    local content = node.content or ""
    if content == "" then return lines end
    for line in (content .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
    return lines
end

local function writeFile(path, text, append)
    local parent, name = splitParent(path)
    if not parent or parent.type ~= "dir" or not name then return false, "No such file or directory" end
    local node = parent.children[name]
    if node then
        if node.type == "dir" then return false, "Is a directory" end
        if not hasPerm(node, "w") then return false, "Permission denied" end
        if append and (node.content or "") ~= "" then
            node.content = node.content .. "\n" .. text
        else
            node.content = text
        end
    else
        if not hasPerm(parent, "w") then return false, "Permission denied" end
        parent.children[name] = newNode("file", text)
    end
    return true
end

local function openReadable(path, cmdName)
    local node, why = getPathObject(path)
    if why == "denied" then
        addTerminalLine(cmdName .. ": " .. path .. ": Permission denied", colors.red)
        return nil
    end
    if not node then
        addTerminalLine(cmdName .. ": " .. path .. ": No such file or directory", colors.red)
        return nil
    end
    if not hasPerm(node, "r") then
        addTerminalLine(cmdName .. ": " .. path .. ": Permission denied", colors.red)
        return nil
    end
    return node
end

local function inputLines(cmdName, filePath)
    if filePath then
        local node = openReadable(filePath, cmdName)
        if not node then return nil end
        if node.type ~= "file" then
            addTerminalLine(cmdName .. ": " .. filePath .. ": Is a directory", colors.red)
            return nil
        end
        return contentLines(node)
    end
    return stdinLines
end

local function permString(node)
    local function triple(d)
        d = tonumber(d) or 0
        return (math.floor(d / 4) % 2 == 1 and "r" or "-")
            .. (math.floor(d / 2) % 2 == 1 and "w" or "-")
            .. (d % 2 == 1 and "x" or "-")
    end
    local mode = nodeMode(node)
    return (node.type == "dir" and "d" or "-") .. triple(mode:sub(1, 1)) .. triple(mode:sub(2, 2)) .. triple(mode:sub(3, 3))
end

local function ensureHome(user)
    local homeDir = getPathObject("/home")
    if homeDir and homeDir.type == "dir" and not homeDir.children[user.name] then
        homeDir.children[user.name] = {type = "dir", children = {}, owner = user.name, mode = "755"}
    end
end

-- ---------- выполнение ----------
local function runScript(path, depth)
    local node = getPathObject(path)
    if not node or node.type ~= "file" then
        addTerminalLine("bash: " .. path .. ": No such file or directory", colors.red)
        return
    end
    if not hasPerm(node, "r") then
        addTerminalLine("bash: " .. path .. ": Permission denied", colors.red)
        return
    end
    for _, line in ipairs(contentLines(node)) do
        line = trim(line)
        if line ~= "" and line:sub(1, 1) ~= "#" then
            addTerminalLine("+ " .. line, colors.darkgray)
            executeLine(line, (depth or 0) + 1)
            if interruptFlag then break end
        end
    end
end

local function runStage(seg, input, ctx)
    local tokens = tokenize(expandVars(seg))
    if #tokens == 0 then return end

    -- присваивание переменной: FOO=bar
    local varName, varValue = tokens[1]:match("^([%a_][%w_]*)=(.*)$")
    if varName then
        env[varName] = varValue
        return
    end

    -- алиасы
    if aliases[tokens[1]] then
        local expanded = tokenize(aliases[tokens[1]])
        table.remove(tokens, 1)
        for i = #expanded, 1, -1 do table.insert(tokens, 1, expanded[i]) end
    end

    local name = tokens[1]
    -- запуск скрипта по пути: ./hack.sh или /tmp/x.sh
    if name:sub(1, 2) == "./" or name:sub(1, 1) == "/" then
        local node = getPathObject(name)
        if not node then
            addTerminalLine("bash: " .. name .. ": No such file or directory", colors.red)
        elseif node.type ~= "file" then
            addTerminalLine("bash: " .. name .. ": Is a directory", colors.red)
        elseif not hasPerm(node, "x") then
            addTerminalLine("bash: " .. name .. ": Permission denied (chmod +x?)", colors.red)
        else
            runScript(name, ctx and ctx.depth)
        end
        return
    end

    local entry = terminalCommands[name:lower()]
    if not entry then
        addTerminalLine("❌ Command not found: " .. name, colors.red)
        return
    end
    tokens[1] = name:lower()

    local savedInput = stdinLines
    stdinLines = input
    local ok, err = pcall(entry.action, tokens, ctx)
    stdinLines = savedInput
    if not ok then
        addTerminalLine("❌ Error: " .. tostring(err), colors.red)
    end
end

local function runPipeline(statement, ctx)
    local segments = splitUnquoted(statement, "|")
    local input = nil
    for idx, seg in ipairs(segments) do
        local isLast = idx == #segments
        local cmdText, mode, target = seg, nil, nil
        if isLast then cmdText, mode, target = splitRedirect(seg) end
        if mode and not target then
            addTerminalLine("bash: syntax error near unexpected token `newline'", colors.red)
            return
        end
        local capture = (not isLast) or (mode ~= nil)
        if capture then captureBuffer = {} end
        runStage(cmdText, input, ctx)
        if capture then
            local buffer = captureBuffer
            captureBuffer = nil
            if not isLast then
                input = buffer
            else
                local ok, why = writeFile(target, table.concat(buffer, "\n"), mode == ">>")
                if not ok then addTerminalLine("bash: " .. target .. ": " .. why, colors.red) end
            end
        end
    end
end

executeLine = function(line, depth)
    depth = depth or 0
    if depth > 6 then
        addTerminalLine("❌ Nesting too deep", colors.red)
        return
    end
    if depth == 0 then
        scrollOffset = 0
        interruptFlag = false
        if autoBootActive then
            bootToken = bootToken + 1
            autoBootActive = false
            addTerminalLine("⏹ Auto-boot cancelled", colors.amber)
        end
    end
    for _, statement in ipairs(splitUnquoted(line, ";")) do
        if interruptFlag then break end
        statement = trim(statement)
        if statement ~= "" then
            if statement:sub(-1) == "&" then
                -- фоновый процесс: виден в ps, убивается через kill
                statement = trim(statement:sub(1, -2))
                local pid, proc = createProcess(statement)
                addTerminalLine("[" .. pid .. "] started: " .. statement, colors.gray)
                task.spawn(function()
                    runPipeline(statement, {proc = proc, depth = depth})
                    if proc.alive then
                        proc.alive = false
                        for i, p in ipairs(kernel.processes) do
                            if p == proc then
                                table.remove(kernel.processes, i)
                                break
                            end
                        end
                        addTerminalLine("[" .. pid .. "] Done: " .. statement, colors.gray)
                    end
                end)
            else
                runPipeline(statement, {depth = depth})
            end
        end
    end
end

local function popSsh()
    local ctx = table.remove(sshStack)
    if not ctx then return end
    fileSystem, users, currentUser, isRoot, currentPath, currentHost =
        ctx.fs, ctx.users, ctx.user, ctx.root, ctx.path, ctx.host
end

local function createSystemProcesses()
    for _, name in ipairs({"init", "systemd-journald", "NetworkManager", "sshd", "jcj_kernel", "dbus-daemon"}) do
        createProcess(name, nil, true)
    end
end

-- ============================================================
-- ===== 11c. ФАЙЛЫ И ТЕКСТОВЫЕ УТИЛИТЫ =====
-- ============================================================
terminalCommands["help"] = {
    desc = "Show commands (help <command> for details)",
    usage = "help [command]",
    action = function(args)
        if args[2] then
            local entry = terminalCommands[args[2]:lower()]
            if not entry then
                addTerminalLine("❌ No help for: " .. args[2], colors.red)
                return
            end
            addTerminalLine(args[2]:lower() .. " — " .. (entry.desc or ""), colors.green)
            if entry.usage then addTerminalLine("   usage: " .. entry.usage, colors.text) end
            return
        end
        addTerminalLine("📖 Commands (help <cmd> / man <cmd> for details):", colors.green)
        local line, count = "", 0
        for _, name in ipairs(sortedKeys(terminalCommands)) do
            line = line .. string.format("%-13s", name)
            count = count + 1
            if count % 5 == 0 then
                addTerminalLine("  " .. line, colors.text)
                line = ""
            end
        end
        if line ~= "" then addTerminalLine("  " .. line, colors.text) end
        addTerminalLine("Tab=autocomplete  ↑/↓=history  PgUp/PgDn=scroll  Ctrl+C=interrupt  cmd1 | cmd2  > file  cmd &", colors.gray)
    end,
}

terminalCommands["man"] = {
    desc = "Manual page for a command",
    usage = "man <command>",
    action = function(args)
        local name = args[2] and args[2]:lower()
        local entry = name and terminalCommands[name]
        if not name then usage("man") return end
        if not entry then
            addTerminalLine("No manual entry for " .. name, colors.red)
            return
        end
        addTerminalLine("NAME", colors.green)
        addTerminalLine("    " .. name .. " - " .. (entry.desc or "no description"), colors.text)
        addTerminalLine("SYNOPSIS", colors.green)
        addTerminalLine("    " .. (entry.usage or name), colors.text)
    end,
}

terminalCommands["pwd"] = {
    desc = "Print working directory",
    action = function()
        addTerminalLine((captureBuffer and "" or "📁 ") .. getFullPath(), colors.green)
    end,
}

terminalCommands["cd"] = {
    desc = "Change directory",
    usage = "cd [path]",
    action = function(args)
        local node, why = getPathObject(args[2] or "~")
        if why == "denied" or (node and node.type == "dir" and not hasPerm(node, "x")) then
            addTerminalLine("cd: " .. (args[2] or "~") .. ": Permission denied", colors.red)
        elseif node and node.type == "dir" then
            currentPath = resolvePath(args[2] or "~")
        elseif node then
            addTerminalLine("cd: " .. args[2] .. ": Not a directory", colors.red)
        else
            addTerminalLine("cd: " .. (args[2] or "~") .. ": No such file or directory", colors.red)
        end
    end,
}

terminalCommands["ls"] = {
    desc = "List directory contents",
    usage = "ls [-l] [-a] [path]",
    action = function(args)
        local showAll, long, path = false, false, nil
        for i = 2, #args do
            local a = args[i]
            if a:sub(1, 1) == "-" and #a > 1 then
                if a:find("a") then showAll = true end
                if a:find("l") then long = true end
            else
                path = a
            end
        end
        local resolved = resolvePath(path or ".")
        local target, why = getPathObject(resolved)
        if why == "denied" or (target and not hasPerm(target, "r")) then
            addTerminalLine("ls: cannot open '" .. resolved .. "': Permission denied", colors.red)
            return
        end
        if not target then
            addTerminalLine("ls: cannot access '" .. resolved .. "': No such file or directory", colors.red)
            return
        end
        if target.type ~= "dir" then
            addTerminalLine(resolved, colors.text)
            return
        end
        decor("📋 " .. resolved .. ":", colors.green)
        local count = 0
        for _, name in ipairs(sortedKeys(target.children)) do
            if showAll or name:sub(1, 1) ~= "." then
                local child = target.children[name]
                local isDir = child.type == "dir"
                local line
                if long then
                    local size = isDir and 4096 or #(child.content or "")
                    line = string.format("%s %-10s %6d %s", permString(child), nodeOwner(child), size, name .. (isDir and "/" or ""))
                elseif captureBuffer then
                    line = name
                else
                    line = "  " .. (isDir and "📁 " or "📄 ") .. name
                end
                addTerminalLine(line, isDir and colors.cyan or colors.text)
                count = count + 1
            end
        end
        if count == 0 then decor("  (empty)", colors.gray) end
    end,
}

terminalCommands["tree"] = {
    desc = "Show directory tree",
    usage = "tree [path]",
    action = function(args)
        local path = resolvePath(args[2] or ".")
        local root = getPathObject(path)
        if not root or root.type ~= "dir" then
            addTerminalLine("tree: " .. path .. ": No such directory", colors.red)
            return
        end
        if not hasPerm(root, "r") then
            addTerminalLine("tree: " .. path .. ": Permission denied", colors.red)
            return
        end
        addTerminalLine(path, colors.cyan)
        local dirs, files = 0, 0
        local function walk(node, prefix, depth)
            local names = sortedKeys(node.children)
            for i, name in ipairs(names) do
                local child = node.children[name]
                local last = i == #names
                local isDir = child.type == "dir"
                addTerminalLine(prefix .. (last and "└── " or "├── ") .. name .. (isDir and "/" or ""), isDir and colors.cyan or colors.text)
                if isDir then
                    dirs = dirs + 1
                    if depth < 6 and hasPerm(child, "r") then
                        walk(child, prefix .. (last and "    " or "│   "), depth + 1)
                    end
                else
                    files = files + 1
                end
            end
        end
        walk(root, "", 1)
        addTerminalLine(dirs .. " directories, " .. files .. " files", colors.gray)
    end,
}

terminalCommands["mkdir"] = {
    desc = "Create directories",
    usage = "mkdir [-p] <dir>...",
    action = function(args)
        local parents, targets = false, {}
        for i = 2, #args do
            if args[i] == "-p" then parents = true else targets[#targets + 1] = args[i] end
        end
        if #targets == 0 then usage("mkdir") return end
        for _, target in ipairs(targets) do
            if parents then
                local node = fileSystem["/"]
                local failed = false
                for part in resolvePath(target):gmatch("[^/]+") do
                    local child = node.children and node.children[part]
                    if not child then
                        if not hasPerm(node, "w") then
                            addTerminalLine("mkdir: cannot create directory '" .. target .. "': Permission denied", colors.red)
                            failed = true
                        else
                            child = newNode("dir")
                            node.children[part] = child
                        end
                    elseif child.type ~= "dir" then
                        addTerminalLine("mkdir: '" .. target .. "': Not a directory", colors.red)
                        failed = true
                    end
                    if failed then break end
                    node = child
                end
            else
                local parent, name = splitParent(target)
                if not parent or parent.type ~= "dir" or not name then
                    addTerminalLine("mkdir: cannot create directory '" .. target .. "': No such file or directory", colors.red)
                elseif parent.children[name] then
                    addTerminalLine("mkdir: cannot create directory '" .. target .. "': File exists", colors.red)
                elseif not hasPerm(parent, "w") then
                    addTerminalLine("mkdir: cannot create directory '" .. target .. "': Permission denied", colors.red)
                else
                    parent.children[name] = newNode("dir")
                    decor("📁 Created: " .. target, colors.green)
                end
            end
        end
    end,
}

terminalCommands["touch"] = {
    desc = "Create empty files",
    usage = "touch <file>...",
    action = function(args)
        if not args[2] then usage("touch") return end
        for i = 2, #args do
            local parent, name = splitParent(args[i])
            if not parent or parent.type ~= "dir" or not name then
                addTerminalLine("touch: cannot touch '" .. args[i] .. "': No such file or directory", colors.red)
            elseif not parent.children[name] then
                if hasPerm(parent, "w") then
                    parent.children[name] = newNode("file")
                    decor("📄 Created: " .. args[i], colors.green)
                else
                    addTerminalLine("touch: cannot touch '" .. args[i] .. "': Permission denied", colors.red)
                end
            end
        end
    end,
}

terminalCommands["rm"] = {
    desc = "Remove files or directories",
    usage = "rm [-r] <path>...",
    action = function(args)
        local recursive, targets = false, {}
        for i = 2, #args do
            local a = args[i]
            if a:sub(1, 1) == "-" and #a > 1 then
                if a:find("r") or a:find("R") then recursive = true end
            else
                targets[#targets + 1] = a
            end
        end
        if #targets == 0 then usage("rm") return end
        for _, target in ipairs(targets) do
            local parent, name, resolved = splitParent(target)
            if resolved == "/" then
                addTerminalLine("rm: it is dangerous to operate recursively on '/'", colors.red)
            elseif not parent or not parent.children or not parent.children[name] then
                addTerminalLine("rm: cannot remove '" .. target .. "': No such file or directory", colors.red)
            else
                local node = parent.children[name]
                if node.type == "dir" and not recursive then
                    addTerminalLine("rm: cannot remove '" .. target .. "': Is a directory (use rm -r)", colors.red)
                elseif not hasPerm(parent, "w") then
                    addTerminalLine("rm: cannot remove '" .. target .. "': Permission denied", colors.red)
                else
                    parent.children[name] = nil
                    -- если удалили текущую папку (или её родителя), поднимаемся выше
                    if currentPath == resolved or currentPath:sub(1, #resolved + 1) == resolved .. "/" then
                        currentPath = resolved:match("^(.*)/[^/]+$") or "/"
                        if currentPath == "" then currentPath = "/" end
                    end
                    decor("🗑️ Removed: " .. target, colors.green)
                end
            end
        end
    end,
}

terminalCommands["rmdir"] = {
    desc = "Remove empty directories",
    usage = "rmdir <dir>",
    action = function(args)
        if not args[2] then usage("rmdir") return end
        local parent, name = splitParent(args[2])
        local node = parent and parent.children and parent.children[name]
        if not node then
            addTerminalLine("rmdir: failed to remove '" .. args[2] .. "': No such file or directory", colors.red)
        elseif node.type ~= "dir" then
            addTerminalLine("rmdir: failed to remove '" .. args[2] .. "': Not a directory", colors.red)
        elseif next(node.children) ~= nil then
            addTerminalLine("rmdir: failed to remove '" .. args[2] .. "': Directory not empty", colors.red)
        elseif not hasPerm(parent, "w") then
            addTerminalLine("rmdir: failed to remove '" .. args[2] .. "': Permission denied", colors.red)
        else
            parent.children[name] = nil
            decor("🗑️ Removed directory: " .. args[2], colors.green)
        end
    end,
}

local function deepCopy(node)
    local copy = {type = node.type, owner = currentUser.name, mode = node.mode}
    if node.type == "file" then
        copy.content = node.content
    else
        copy.children = {}
        for name, child in pairs(node.children) do copy.children[name] = deepCopy(child) end
    end
    return copy
end

-- общая часть cp и mv: находит папку назначения и имя
local function resolveDestination(cmdName, srcResolved, dstArg)
    local dstNode = getPathObject(dstArg)
    local srcName = srcResolved:match("([^/]+)$")
    local parent, name
    if dstNode and dstNode.type == "dir" then
        parent, name = dstNode, srcName
    else
        parent, name = splitParent(dstArg)
    end
    if not parent or parent.type ~= "dir" or not name then
        addTerminalLine(cmdName .. ": cannot create '" .. dstArg .. "': No such file or directory", colors.red)
        return nil
    end
    if not hasPerm(parent, "w") then
        addTerminalLine(cmdName .. ": cannot create '" .. dstArg .. "': Permission denied", colors.red)
        return nil
    end
    return parent, name
end

terminalCommands["cp"] = {
    desc = "Copy files and directories",
    usage = "cp [-r] <source> <destination>",
    action = function(args)
        local recursive, rest = false, {}
        for i = 2, #args do
            local a = args[i]
            if a:sub(1, 1) == "-" and #a > 1 then
                if a:find("r") or a:find("R") then recursive = true end
            else
                rest[#rest + 1] = a
            end
        end
        if #rest < 2 then usage("cp") return end
        local src, dst = rest[1], rest[2]
        local node = openReadable(src, "cp")
        if not node then return end
        if node.type == "dir" and not recursive then
            addTerminalLine("cp: -r not specified; omitting directory '" .. src .. "'", colors.red)
            return
        end
        local parent, name = resolveDestination("cp", resolvePath(src), dst)
        if not parent then return end
        parent.children[name] = deepCopy(node)
        decor("📄 Copied: " .. src .. " -> " .. dst, colors.green)
    end,
}

terminalCommands["mv"] = {
    desc = "Move or rename files and directories",
    usage = "mv <source> <destination>",
    action = function(args)
        if not args[3] then usage("mv") return end
        local src, dst = args[2], args[3]
        local srcParent, srcName, srcResolved = splitParent(src)
        if not srcParent or not srcParent.children or not srcParent.children[srcName] then
            addTerminalLine("mv: cannot stat '" .. src .. "': No such file or directory", colors.red)
            return
        end
        if not hasPerm(srcParent, "w") then
            addTerminalLine("mv: cannot move '" .. src .. "': Permission denied", colors.red)
            return
        end
        local dstResolved = resolvePath(dst)
        if dstResolved == srcResolved or dstResolved:sub(1, #srcResolved + 1) == srcResolved .. "/" then
            addTerminalLine("mv: cannot move '" .. src .. "' to a subdirectory of itself", colors.red)
            return
        end
        local parent, name = resolveDestination("mv", srcResolved, dst)
        if not parent then return end
        local node = srcParent.children[srcName]
        srcParent.children[srcName] = nil
        parent.children[name] = node
        if currentPath == srcResolved or currentPath:sub(1, #srcResolved + 1) == srcResolved .. "/" then
            currentPath = "/"
        end
        decor("📦 Moved: " .. src .. " -> " .. dst, colors.green)
    end,
}

terminalCommands["cat"] = {
    desc = "Read files (or pipe input)",
    usage = "cat <file>...",
    action = function(args)
        if not args[2] then
            if stdinLines then
                for _, l in ipairs(stdinLines) do addTerminalLine(l, colors.text) end
                return
            end
            usage("cat")
            return
        end
        for i = 2, #args do
            local node = openReadable(args[i], "cat")
            if node then
                if node.type ~= "file" then
                    addTerminalLine("cat: " .. args[i] .. ": Is a directory", colors.red)
                else
                    decor("📄 " .. args[i] .. ":", colors.green)
                    if (node.content or "") ~= "" then
                        addTerminalLine(node.content, colors.text)
                    else
                        decor("(empty)", colors.gray)
                    end
                end
            end
        end
    end,
}

terminalCommands["echo"] = {
    desc = "Print text (supports $VARIABLES, > and >>)",
    usage = "echo <text>",
    action = function(args)
        addTerminalLine((captureBuffer and "" or "💬 ") .. table.concat(args, " ", 2), colors.text)
    end,
}

local function parseCount(args, default)
    local n, file = default, nil
    local i = 2
    while i <= #args do
        local a = args[i]
        if a == "-n" then
            n = tonumber(args[i + 1]) or default
            i = i + 2
        elseif a:match("^%-%d+$") then
            n = tonumber(a:sub(2))
            i = i + 1
        else
            file = a
            i = i + 1
        end
    end
    return n, file
end

terminalCommands["head"] = {
    desc = "Show the first lines of a file",
    usage = "head [-n N] [file]",
    action = function(args)
        local n, file = parseCount(args, 10)
        if not file and not stdinLines then usage("head") return end
        local lines = inputLines("head", file)
        if not lines then return end
        for i = 1, math.min(n, #lines) do addTerminalLine(lines[i], colors.text) end
    end,
}

terminalCommands["tail"] = {
    desc = "Show the last lines of a file",
    usage = "tail [-n N] [file]",
    action = function(args)
        local n, file = parseCount(args, 10)
        if not file and not stdinLines then usage("tail") return end
        local lines = inputLines("tail", file)
        if not lines then return end
        for i = math.max(1, #lines - n + 1), #lines do addTerminalLine(lines[i], colors.text) end
    end,
}

terminalCommands["wc"] = {
    desc = "Count lines, words and characters",
    usage = "wc [-l|-w|-c] [file]",
    action = function(args)
        local flag, file
        for i = 2, #args do
            if args[i]:sub(1, 1) == "-" then flag = args[i] else file = args[i] end
        end
        if not file and not stdinLines then usage("wc") return end
        local lines = inputLines("wc", file)
        if not lines then return end
        local words, chars = 0, 0
        for _, l in ipairs(lines) do
            for _ in l:gmatch("%S+") do words = words + 1 end
            chars = chars + #l + 1
        end
        local out
        if flag == "-l" then out = tostring(#lines)
        elseif flag == "-w" then out = tostring(words)
        elseif flag == "-c" then out = tostring(chars)
        else out = string.format("%d %d %d", #lines, words, chars) end
        addTerminalLine(out .. (file and (" " .. file) or ""), colors.text)
    end,
}

terminalCommands["sort"] = {
    desc = "Sort lines",
    usage = "sort [-r] [file]",
    action = function(args)
        local reverse, file = false, nil
        for i = 2, #args do
            if args[i] == "-r" then reverse = true else file = args[i] end
        end
        if not file and not stdinLines then usage("sort") return end
        local lines = inputLines("sort", file)
        if not lines then return end
        local copy = {table.unpack(lines)}
        table.sort(copy, function(a, b)
            if reverse then return a > b end
            return a < b
        end)
        for _, l in ipairs(copy) do addTerminalLine(l, colors.text) end
    end,
}

terminalCommands["uniq"] = {
    desc = "Collapse adjacent duplicate lines",
    usage = "uniq [-c] [file]",
    action = function(args)
        local counting, file = false, nil
        for i = 2, #args do
            if args[i] == "-c" then counting = true else file = args[i] end
        end
        if not file and not stdinLines then usage("uniq") return end
        local lines = inputLines("uniq", file)
        if not lines then return end
        local i = 1
        while i <= #lines do
            local j = i
            while j < #lines and lines[j + 1] == lines[i] do j = j + 1 end
            addTerminalLine((counting and string.format("%4d ", j - i + 1) or "") .. lines[i], colors.text)
            i = j + 1
        end
    end,
}

terminalCommands["grep"] = {
    desc = "Search text in files or piped input",
    usage = "grep [-i] [-v] [-n] [-r] <pattern> [file|dir...]",
    action = function(args)
        local ignoreCase, invert, numbered, recursive = false, false, false, false
        local rest = {}
        for i = 2, #args do
            local a = args[i]
            if a:sub(1, 1) == "-" and #a > 1 and #rest == 0 then
                if a:find("i") then ignoreCase = true end
                if a:find("v") then invert = true end
                if a:find("n") then numbered = true end
                if a:find("r") or a:find("R") then recursive = true end
            else
                rest[#rest + 1] = a
            end
        end
        local pattern = rest[1]
        if not pattern then usage("grep") return end
        local needle = ignoreCase and pattern:lower() or pattern

        local function scan(lines, label)
            for n, line in ipairs(lines) do
                local hay = ignoreCase and line:lower() or line
                if (hay:find(needle, 1, true) ~= nil) ~= invert then
                    local prefix = (label and (label .. ":") or "") .. (numbered and (n .. ":") or "")
                    addTerminalLine(prefix .. line, colors.text)
                end
            end
        end

        local targets = {}
        for i = 2, #rest do targets[#targets + 1] = rest[i] end
        if #targets == 0 then
            if recursive then
                targets = {"."}
            elseif stdinLines then
                scan(stdinLines, nil)
                return
            else
                usage("grep")
                return
            end
        end
        local multi = #targets > 1 or recursive

        local function visit(node, displayPath)
            if node.type == "file" then
                if hasPerm(node, "r") then scan(contentLines(node), multi and displayPath or nil) end
            elseif recursive and hasPerm(node, "r") then
                for _, name in ipairs(sortedKeys(node.children)) do
                    visit(node.children[name], displayPath .. "/" .. name)
                end
            end
        end

        for _, target in ipairs(targets) do
            local node = openReadable(target, "grep")
            if node then
                if node.type == "dir" and not recursive then
                    addTerminalLine("grep: " .. target .. ": Is a directory", colors.red)
                else
                    visit(node, target)
                end
            end
        end
    end,
}

terminalCommands["find"] = {
    desc = "Search for files by name",
    usage = "find [path] [-name pattern]",
    action = function(args)
        local startPath, namePattern = ".", nil
        local i = 2
        while i <= #args do
            if args[i] == "-name" then
                namePattern = args[i + 1]
                i = i + 2
            else
                startPath = args[i]
                i = i + 1
            end
        end
        local root = getPathObject(startPath)
        if not root then
            addTerminalLine("find: '" .. startPath .. "': No such file or directory", colors.red)
            return
        end
        local luaPattern
        if namePattern then
            local escaped = namePattern:gsub("[%^%$%(%)%%%.%[%]%+%-]", "%%%0")
            escaped = escaped:gsub("%*", ".*")
            escaped = escaped:gsub("%?", ".")
            luaPattern = "^" .. escaped .. "$"
        end
        local function walk(node, path)
            local name = path:match("([^/]+)$") or "/"
            if not luaPattern or name:match(luaPattern) then
                addTerminalLine(path, colors.text)
            end
            if node.type == "dir" and hasPerm(node, "r") then
                for _, childName in ipairs(sortedKeys(node.children)) do
                    walk(node.children[childName], (path == "/" and "" or path) .. "/" .. childName)
                end
            end
        end
        walk(root, startPath)
    end,
}

-- chmod: восьмеричные (755) и символьные (+x, u-w, go+r) режимы
local function applyMode(node, spec)
    if spec:match("^[0-7][0-7][0-7]$") then
        node.mode = spec
        return true
    end
    local who, op, perms = spec:match("^([ugoa]*)([%+%-=])([rwx]*)$")
    if not op then return false end
    if who == "" then who = "a" end
    local current = nodeMode(node)
    local digits = {tonumber(current:sub(1, 1)), tonumber(current:sub(2, 2)), tonumber(current:sub(3, 3))}
    local bits = 0
    if perms:find("r") then bits = bits + 4 end
    if perms:find("w") then bits = bits + 2 end
    if perms:find("x") then bits = bits + 1 end
    local function applyTo(i)
        if op == "+" then
            digits[i] = bit32.bor(digits[i], bits)
        elseif op == "-" then
            digits[i] = bit32.band(digits[i], bit32.bnot(bits))
        else
            digits[i] = bits
        end
    end
    local index = {u = 1, g = 2, o = 3}
    for ch in who:gmatch(".") do
        if ch == "a" then
            applyTo(1)
            applyTo(2)
            applyTo(3)
        else
            applyTo(index[ch])
        end
    end
    node.mode = digits[1] .. digits[2] .. digits[3]
    return true
end

terminalCommands["chmod"] = {
    desc = "Change file permissions",
    usage = "chmod <755|+x|u-w|go+r> <file>",
    action = function(args)
        if not args[3] then usage("chmod") return end
        local node = getPathObject(args[3])
        if not node then
            addTerminalLine("chmod: cannot access '" .. args[3] .. "': No such file or directory", colors.red)
        elseif nodeOwner(node) ~= currentUser.name and not isRoot then
            addTerminalLine("chmod: changing permissions of '" .. args[3] .. "': Operation not permitted", colors.red)
        elseif not applyMode(node, args[2]) then
            addTerminalLine("chmod: invalid mode: '" .. args[2] .. "'", colors.red)
        else
            decor("🔐 " .. args[3] .. " -> " .. nodeMode(node) .. " (" .. permString(node) .. ")", colors.green)
        end
    end,
}

terminalCommands["chown"] = {
    desc = "Change file owner (root only)",
    usage = "chown [-R] <user> <file>",
    action = function(args)
        if not checkRoot() then return end
        local recursive, rest = false, {}
        for i = 2, #args do
            if args[i] == "-R" then recursive = true else rest[#rest + 1] = args[i] end
        end
        if #rest < 2 then usage("chown") return end
        local ownerName = rest[1]:match("^([^:]+)")
        local exists = false
        for _, u in ipairs(users) do
            if u.name == ownerName then exists = true end
        end
        if not exists then
            addTerminalLine("chown: invalid user: '" .. ownerName .. "'", colors.red)
            return
        end
        local node = getPathObject(rest[2])
        if not node then
            addTerminalLine("chown: cannot access '" .. rest[2] .. "': No such file or directory", colors.red)
            return
        end
        if recursive then chownTree(node, ownerName) else node.owner = ownerName end
        decor("👤 Owner of " .. rest[2] .. " is now " .. ownerName, colors.green)
    end,
}

-- ---------- текстовый редактор (nano / vim / vi) ----------
local function editFile(name, args)
    local path = args[2]
    if not path then usage(name) return end
    local parent, fileName = splitParent(path)
    if not parent or parent.type ~= "dir" or not fileName then
        addTerminalLine(name .. ": " .. path .. ": No such directory", colors.red)
        return
    end
    local node = parent.children[fileName]
    local lines = {}
    local canWrite = true
    if node then
        if node.type ~= "file" then
            addTerminalLine(name .. ": " .. path .. ": Is a directory", colors.red)
            return
        end
        if not hasPerm(node, "r") then
            addTerminalLine(name .. ": " .. path .. ": Permission denied", colors.red)
            return
        end
        lines = contentLines(node)
        canWrite = hasPerm(node, "w")
    elseif not hasPerm(parent, "w") then
        addTerminalLine(name .. ": " .. path .. ": Permission denied", colors.red)
        return
    end

    local modified = false
    local message = nil

    local function show()
        renderSuspended = true
        terminalLines = {}
        scrollOffset = 0
        addTerminalLine("── " .. name .. ": " .. fileName .. (modified and " [modified]" or "") .. (canWrite and "" or " [read-only]") .. " ──", colors.green)
        local window = maxLines - 6
        for i = math.max(1, #lines - window + 1), #lines do
            addTerminalLine(string.format("%3d│ %s", i, lines[i]), colors.text)
        end
        if #lines == 0 then addTerminalLine("  (empty file)", colors.gray) end
        addTerminalLine("─────────────", colors.gray)
        addTerminalLine("text+Enter = add line | :w save | :q quit | :wq | :q! discard", colors.gray)
        addTerminalLine(":d N delete line | :e N text replace | :i N text insert before", colors.gray)
        if message then addTerminalLine(message, colors.amber) end
        renderSuspended = false
        updateTerminalDisplay()
    end

    local function save()
        if not canWrite then
            message = "⛔ Permission denied (read-only)"
            return false
        end
        local text = table.concat(lines, "\n")
        if node then
            node.content = text
        else
            node = newNode("file", text)
            parent.children[fileName] = node
        end
        modified = false
        message = "💾 Saved " .. fileName
        return true
    end

    while true do
        show()
        message = nil
        local input = readLine("edit> ", false)
        if input == nil then break end
        local cmd, rest = input:match("^:(%S+)%s*(.*)$")
        if cmd == "q" then
            if modified then
                message = "Unsaved changes! Use :wq, :w or :q! to discard"
            else
                break
            end
        elseif cmd == "q!" then
            break
        elseif cmd == "w" then
            save()
        elseif cmd == "wq" then
            if save() then break end
        elseif cmd == "d" then
            local n = tonumber(rest)
            if n and lines[n] then
                table.remove(lines, n)
                modified = true
            else
                message = "Usage: :d N"
            end
        elseif cmd == "e" or cmd == "i" then
            local n, text = rest:match("^(%d+)%s*(.*)$")
            n = tonumber(n)
            if n and (cmd == "e" and lines[n] or (cmd == "i" and n >= 1 and n <= #lines + 1)) then
                if cmd == "e" then lines[n] = text else table.insert(lines, n, text) end
                modified = true
            else
                message = "Usage: :" .. cmd .. " N text"
            end
        elseif cmd then
            message = "Unknown command: :" .. cmd
        else
            table.insert(lines, input)
            modified = true
        end
    end
    addTerminalLine("📝 Closed " .. fileName, colors.gray)
end

for _, editorName in ipairs({"nano", "vim", "vi"}) do
    terminalCommands[editorName] = {
        desc = "Simple line-based text editor",
        usage = editorName .. " <file>",
        action = function(args) editFile(editorName, args) end,
    }
end

-- ============================================================
-- ===== 11d. ПОЛЬЗОВАТЕЛИ, СИСТЕМА, ПРОЦЕССЫ, ПАКЕТЫ, ЗАГРУЗКА =====
-- ============================================================
-- База пакетов (используется apt, pacman, neofetch и сохранением состояния)
local repo = {
    htop = "3.3.0", vim = "9.1", nano = "7.2", git = "2.43.0", python3 = "3.11.6", tree = "2.1.1",
    neofetch = "7.1.0", cmatrix = "2.0", sl = "5.02", cowsay = "3.04", figlet = "2.2.5",
    nmap = "7.94", curl = "8.5.0", wget = "1.21.4", tmux = "3.4",
}
local installed = {jcj_kernel = "3.0.0", murder_drones = "2.0.0", robux = "1.0.0", bash = "5.2", coreutils = "9.4"}
local protectedPackages = {jcj_kernel = true, bash = true, coreutils = true}

terminalCommands["whoami"] = {
    desc = "Print current user",
    action = function()
        if captureBuffer then
            addTerminalLine(currentUser.name, colors.green)
            return
        end
        addTerminalLine("👤 " .. currentUser.name .. (isRoot and " 👑 ROOT" or ""), colors.green)
    end,
}

terminalCommands["hostname"] = {
    desc = "Print machine name",
    action = function() addTerminalLine(currentHost, colors.text) end,
}

terminalCommands["su"] = {
    desc = "Switch user (password required unless root)",
    usage = "su [-] [user]",
    action = function(args)
        local idx, login = 2, false
        if args[2] == "-" then
            login = true
            idx = 3
        end
        local targetName = args[idx] or "root"
        local target
        for _, u in ipairs(users) do
            if u.name == targetName then target = u end
        end
        if not target then
            addTerminalLine("su: user " .. targetName .. " does not exist", colors.red)
            return
        end
        if not isRoot and target.name ~= currentUser.name then
            if not askPassword(target, "Password: ") then
                addTerminalLine("su: Authentication failure", colors.red)
                return
            end
        end
        currentUser = target
        isRoot = target.is_root == true
        if login then currentPath = homeOf(target) end
        if isRoot then
            addTerminalLine("👑 You are now root!", colors.amber)
        else
            addTerminalLine("👤 Switched to: " .. target.name, colors.green)
        end
    end,
}

terminalCommands["sudo"] = {
    desc = "Run a command as root (asks your password)",
    usage = "sudo <command> [args]",
    action = function(args, ctx)
        if not args[2] then usage("sudo") return end
        if not hasSudoAccess(currentUser) then
            addTerminalLine(currentUser.name .. " is not in the sudoers file. This incident will be reported.", colors.red)
            return
        end
        if not isRoot and os.time() - lastSudoTime > 300 then
            if not askPassword(currentUser, "[sudo] password for " .. currentUser.name .. ": ") then return end
        end
        lastSudoTime = os.time()
        local sub = {}
        for i = 2, #args do sub[#sub + 1] = args[i] end
        local entry = terminalCommands[sub[1]:lower()]
        if not entry then
            addTerminalLine("❌ Command not found: " .. sub[1], colors.red)
            return
        end
        local oldUser, oldRoot = currentUser, isRoot
        isRoot = true
        currentUser = users[1]
        addTerminalLine("👑 Executing '" .. sub[1] .. "' as root...", colors.amber)
        local ok, err = pcall(entry.action, sub, ctx)
        -- `sudo su` должен оставить root-сессию; всё остальное возвращает права
        if sub[1]:lower() ~= "su" then currentUser, isRoot = oldUser, oldRoot end
        if not ok then addTerminalLine("❌ Error: " .. tostring(err), colors.red) end
    end,
}

terminalCommands["passwd"] = {
    desc = "Change a password",
    usage = "passwd [user]",
    action = function(args)
        local target = currentUser
        if args[2] then
            target = nil
            for _, u in ipairs(users) do
                if u.name == args[2] then target = u end
            end
            if not target then
                addTerminalLine("passwd: user '" .. args[2] .. "' does not exist", colors.red)
                return
            end
        end
        if target.name ~= currentUser.name and not isRoot then
            addTerminalLine("passwd: You may not view or modify password information for " .. target.name, colors.red)
            return
        end
        if not isRoot then
            local current = readLine("Current password: ", true)
            if current == nil then return end
            if current ~= target.password then
                addTerminalLine("passwd: Authentication token manipulation error", colors.red)
                return
            end
        end
        local first = readLine("New password: ", true)
        if first == nil then return end
        if first == "" then
            addTerminalLine("passwd: password cannot be empty", colors.red)
            return
        end
        local second = readLine("Retype new password: ", true)
        if second == nil then return end
        if first ~= second then
            addTerminalLine("Sorry, passwords do not match.", colors.red)
            return
        end
        target.password = first
        addTerminalLine("✅ passwd: password updated successfully", colors.green)
    end,
}

terminalCommands["useradd"] = {
    desc = "Add a user (root only)",
    usage = "useradd <username>",
    action = function(args)
        if not checkRoot() then return end
        local name = args[2]
        if not name then usage("useradd") return end
        if not name:match("^[%a_][%w_%-]*$") then
            addTerminalLine("useradd: invalid user name '" .. name .. "'", colors.red)
            return
        end
        for _, u in ipairs(users) do
            if u.name == name then
                addTerminalLine("useradd: user '" .. name .. "' already exists", colors.red)
                return
            end
        end
        local pw = readLine("Set password for " .. name .. ": ", true)
        if pw == nil then return end
        if pw == "" then pw = "password" end
        local newUser = {
            name = name, uid = 2000 + #users, gid = 100, home = "/home/" .. name,
            shell = "/bin/bash", password = pw, is_root = false, groups = {"users"},
        }
        table.insert(users, newUser)
        ensureHome(newUser)
        addTerminalLine("✅ User " .. name .. " created (home: /home/" .. name .. ")", colors.green)
    end,
}

terminalCommands["userdel"] = {
    desc = "Delete a user (root only, home is kept)",
    usage = "userdel <username>",
    action = function(args)
        if not checkRoot() then return end
        if not args[2] then usage("userdel") return end
        if args[2] == "root" or args[2] == currentUser.name then
            addTerminalLine("userdel: cannot remove this user", colors.red)
            return
        end
        for i, u in ipairs(users) do
            if u.name == args[2] then
                table.remove(users, i)
                addTerminalLine("🗑️ User " .. args[2] .. " removed", colors.green)
                return
            end
        end
        addTerminalLine("userdel: user '" .. args[2] .. "' does not exist", colors.red)
    end,
}

-- ---------- окружение ----------
terminalCommands["export"] = {
    desc = "Set an environment variable",
    usage = "export NAME=value",
    action = function(args)
        local spec = table.concat(args, " ", 2)
        local name, value = spec:match("^([%a_][%w_]*)=(.*)$")
        if not name then usage("export") return end
        env[name] = value
    end,
}

terminalCommands["env"] = {
    desc = "Print environment variables",
    action = function()
        local all = {
            USER = currentUser.name, HOME = homeOf(currentUser), PWD = currentPath,
            HOSTNAME = currentHost, SHELL = currentUser.shell,
        }
        for k, v in pairs(env) do all[k] = v end
        for _, key in ipairs(sortedKeys(all)) do
            addTerminalLine(key .. "=" .. tostring(all[key]), colors.text)
        end
    end,
}

terminalCommands["alias"] = {
    desc = "Define or list command aliases",
    usage = "alias [name='command']",
    action = function(args)
        if not args[2] then
            for _, name in ipairs(sortedKeys(aliases)) do
                addTerminalLine("alias " .. name .. "='" .. aliases[name] .. "'", colors.text)
            end
            return
        end
        local spec = table.concat(args, " ", 2)
        local name, value = spec:match("^([%w_%.%-]+)=(.*)$")
        if name then
            aliases[name] = value
        elseif aliases[spec] then
            addTerminalLine("alias " .. spec .. "='" .. aliases[spec] .. "'", colors.text)
        else
            addTerminalLine("alias: " .. spec .. ": not found", colors.red)
        end
    end,
}

terminalCommands["unalias"] = {
    desc = "Remove an alias",
    usage = "unalias <name>",
    action = function(args)
        if not args[2] then usage("unalias") return end
        if aliases[args[2]] then
            aliases[args[2]] = nil
        else
            addTerminalLine("unalias: " .. args[2] .. ": not found", colors.red)
        end
    end,
}

terminalCommands["history"] = {
    desc = "Show command history",
    action = function()
        for i, cmd in ipairs(commandHistory) do
            addTerminalLine(string.format("%4d  %s", i, cmd), colors.text)
        end
    end,
}

-- ---------- процессы и время ----------
terminalCommands["sleep"] = {
    desc = "Wait N seconds (try: sleep 30 &)",
    usage = "sleep <seconds>",
    action = function(args, ctx)
        local secs = tonumber(args[2])
        if not secs then usage("sleep") return end
        local waited = 0
        while waited < secs and not stopRequested(ctx) do
            task.wait(0.1)
            waited = waited + 0.1
        end
    end,
}

terminalCommands["yes"] = {
    desc = "Repeat text until interrupted (Ctrl+C / Enter / kill)",
    usage = "yes [text]",
    action = function(args, ctx)
        local text = #args > 1 and table.concat(args, " ", 2) or "y"
        local n = 0
        while not stopRequested(ctx) and n < 2000 do
            addTerminalLine(text, colors.text)
            n = n + 1
            task.wait(0.05)
        end
    end,
}

terminalCommands["watch"] = {
    desc = "Run a command repeatedly (Ctrl+C / Enter to stop)",
    usage = "watch [-n sec] <command>",
    action = function(args, ctx)
        local interval, idx = 2, 2
        if args[2] == "-n" then
            interval = tonumber(args[3]) or 2
            idx = 4
        end
        local cmd = table.concat(args, " ", idx)
        if cmd == "" then usage("watch") return end
        local runs = 0
        while not stopRequested(ctx) and runs < 300 do
            renderSuspended = true
            terminalLines = {}
            addTerminalLine("Every " .. interval .. "s: " .. cmd .. "    " .. os.date("%H:%M:%S"), colors.green)
            executeLine(cmd, 1)
            renderSuspended = false
            updateTerminalDisplay()
            runs = runs + 1
            local waited = 0
            while waited < interval and not stopRequested(ctx) do
                task.wait(0.1)
                waited = waited + 0.1
            end
        end
    end,
}

local function renderTop()
    renderSuspended = true
    terminalLines = {}
    local ping, mem = getPingMs(), getMemoryMb()
    addTerminalLine(string.format("top - %s  up %s  fps %d", os.date("%H:%M:%S"), uptimeString(), fps), colors.green)
    addTerminalLine(string.format("Players: %d   Ping: %s   Mem: %s", #game.Players:GetPlayers(),
        ping and (ping .. " ms") or "n/a", mem and (mem .. " MB") or "n/a"), colors.text)
    addTerminalLine("Tasks: " .. #kernel.processes .. " total   (Enter / Ctrl+C to quit)", colors.text)
    addTerminalLine("  PID USER       CPU%  MEM%  COMMAND", colors.amber)
    for i, proc in ipairs(kernel.processes) do
        if i > 12 then break end
        local cpu = proc.system and math.random(0, 3) or math.random(1, 40)
        local memory = proc.system and math.random(1, 4) or math.random(1, 9)
        addTerminalLine(string.format("%5d %-10s %4d  %4d  %s", proc.pid, proc.user or "root", cpu, memory, proc.name), colors.text)
    end
    renderSuspended = false
    updateTerminalDisplay()
end

local function topAction(args, ctx)
    local frames = 0
    while not stopRequested(ctx) and frames < 120 do
        renderTop()
        frames = frames + 1
        local waited = 0
        while waited < 1 and not stopRequested(ctx) do
            task.wait(0.1)
            waited = waited + 0.1
        end
    end
    addTerminalLine("top: stopped", colors.gray)
end

terminalCommands["top"] = {desc = "Live process and system monitor", action = topAction}
terminalCommands["htop"] = {desc = "Live process and system monitor", action = topAction}

terminalCommands["uptime"] = {
    desc = "Time since boot",
    action = function()
        addTerminalLine((captureBuffer and "" or "⏱️ ") .. "up " .. uptimeString(), colors.green)
    end,
}

terminalCommands["neofetch"] = {
    desc = "System information",
    action = function()
        local machine = machines[currentHost]
        local distro = machine and machine.distro or kernel.distro
        local mem = getMemoryMb()
        addTerminalLine("        .-.        " .. currentUser.name .. "@" .. currentHost, colors.green)
        addTerminalLine("       (o o)       ----------------", colors.green)
        addTerminalLine("       | O \\       OS: " .. distro .. " " .. kernel.architecture, colors.green)
        addTerminalLine("        \\   \\      Kernel: " .. kernel.name .. " " .. kernel.version, colors.green)
        addTerminalLine("         `~~~'     Uptime: " .. uptimeString(), colors.green)
        addTerminalLine("                   Shell: " .. (currentUser.shell or "/bin/bash"), colors.text)
        addTerminalLine("                   Theme: " .. currentThemeName, colors.text)
        local packageCount = 0
        for _ in pairs(installed) do packageCount = packageCount + 1 end
        addTerminalLine("                   Packages: " .. packageCount, colors.text)
        addTerminalLine("                   Memory: " .. (mem and (mem .. " MiB") or "n/a") .. " / 16384 MiB", colors.text)
    end,
}

-- ---------- скрипты ----------
local function bashAction(args)
    if args[2] == "-c" then
        executeLine(args[3] or "", 1)
    elseif args[2] then
        runScript(args[2], 1)
    else
        addTerminalLine("GNU bash 5.2 — usage: bash <script> | bash -c \"cmd1; cmd2\"", colors.text)
    end
end
terminalCommands["bash"] = {desc = "Run a script or command line", usage = "bash <script> | bash -c \"cmds\"", action = bashAction}
terminalCommands["sh"] = {desc = "Run a script or command line", usage = "sh <script> | sh -c \"cmds\"", action = bashAction}
terminalCommands["source"] = {desc = "Run a script", usage = "source <script>", action = bashAction}

-- ---------- графика, темы, сохранение ----------
terminalCommands["startx"] = {
    desc = "Start the X11 desktop (windows: Files, Clock, Monitor, Notes)",
    action = function() openDesktop("X11") end,
}
terminalCommands["wayland"] = {
    desc = "Start the Wayland desktop",
    action = function() openDesktop("Wayland") end,
}
terminalCommands["stopx"] = {
    desc = "Stop the graphical desktop",
    action = function() closeDesktop() end,
}

terminalCommands["theme"] = {
    desc = "Change terminal colors",
    usage = "theme [classic|amber|cyberpunk|ice]",
    action = function(args)
        if not args[2] then
            addTerminalLine("🎨 Themes:", colors.green)
            for _, name in ipairs(sortedKeys(themes)) do
                addTerminalLine("  " .. name .. (name == currentThemeName and "   (current)" or ""), colors.text)
            end
            return
        end
        if applyTheme(args[2]) then
            addTerminalLine("🎨 Theme: " .. args[2], colors.green)
        else
            addTerminalLine("❌ Unknown theme: " .. args[2], colors.red)
        end
    end,
}

terminalCommands["save"] = {
    desc = "Save the filesystem and settings (needs Outpost3Save.server.lua)",
    action = function()
        if saveState(false) then addTerminalLine("💾 State saved", colors.green) end
    end,
}
terminalCommands["load"] = {
    desc = "Load the saved filesystem and settings",
    action = function()
        if loadState(false) then addTerminalLine("💾 State restored", colors.green) end
    end,
}

-- ---------- ssh ----------
terminalCommands["ssh"] = {
    desc = "Connect to another machine (kali, arch, blackarch)",
    usage = "ssh [user@]<host>   hosts: kali, arch, blackarch",
    action = function(args)
        local target = args[2]
        if not target then usage("ssh") return end
        local userName, host = target:match("^(.-)@(.+)$")
        if not host then
            host, userName = target, currentUser.name
        end
        local machine = machines[host]
        if not machine then
            if host == currentHost then
                addTerminalLine("ssh: you are already on " .. host, colors.amber)
            else
                addTerminalLine("ssh: Could not resolve hostname " .. host .. ": Name or service not known", colors.red)
            end
            return
        end
        addTerminalLine("🔗 Connecting to " .. host .. " (" .. machine.ip .. ")...", colors.green)
        task.wait(0.4)
        local remoteUser
        for _, u in ipairs(machine.users) do
            if u.name == userName then remoteUser = u end
        end
        if not remoteUser then
            addTerminalLine(userName .. "@" .. host .. ": Permission denied (publickey,password).", colors.red)
            return
        end
        if not askPassword(remoteUser, userName .. "@" .. host .. "'s password: ") then return end
        table.insert(sshStack, {fs = fileSystem, users = users, user = currentUser, root = isRoot, path = currentPath, host = currentHost})
        fileSystem, users, currentUser, isRoot, currentPath, currentHost =
            machine.fs, machine.users, remoteUser, remoteUser.is_root == true, homeOf(remoteUser), host
        addTerminalLine("✅ Connected to " .. host .. " — " .. machine.distro, colors.green)
        addTerminalLine("   Last login: " .. os.date("%a %b %d %H:%M:%S") .. " from 192.168.1.100", colors.gray)
        addTerminalLine("   Type 'exit' to close the connection.", colors.gray)
    end,
}

terminalCommands["exit"] = {
    desc = "Close ssh session, or close the terminal",
    action = function()
        if #sshStack > 0 then
            local host = currentHost
            popSsh()
            addTerminalLine("Connection to " .. host .. " closed.", colors.amber)
        else
            addTerminalLine("🖥️ Terminal closed", colors.gray)
            setTerminalActive(false)
        end
    end,
}

-- ---------- пакетные менеджеры (общая реализация apt / pacman) ----------
local function makePackageManager(title, summary, ops)
    return {
        desc = title,
        usage = summary,
        action = function(args)
            local op = args[2]
            if not op then
                addTerminalLine("📦 " .. title, colors.green)
                addTerminalLine("   " .. summary, colors.text)
                return
            end
            local kind = ops[op]
            if not kind then
                addTerminalLine("❌ Unknown operation: " .. op, colors.red)
                return
            end
            if kind ~= "list" and kind ~= "search" and not checkRoot() then return end

            if kind == "update" then
                addTerminalLine("[+] Updating package lists...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] Package lists are up to date", colors.green)
            elseif kind == "upgrade" then
                addTerminalLine("[+] Checking for upgrades...", colors.green)
                task.wait(0.5)
                addTerminalLine("[✓] 0 upgraded, 0 newly installed", colors.green)
            elseif kind == "install" then
                if not args[3] then usage(args[1]) return end
                for i = 3, #args do
                    local pkg = args[i]
                    if installed[pkg] then
                        addTerminalLine("ℹ️ " .. pkg .. " is already installed", colors.amber)
                    elseif not repo[pkg] then
                        addTerminalLine("E: Unable to locate package " .. pkg, colors.red)
                    else
                        addTerminalLine("[+] Installing " .. pkg .. "...", colors.green)
                        task.wait(0.5)
                        installed[pkg] = repo[pkg]
                        local bin = getPathObject("/usr/bin")
                        if bin and bin.type == "dir" then
                            bin.children[pkg] = {type = "file", owner = "root", mode = "755", content = "#!/bin/sh\n# " .. pkg .. " " .. repo[pkg]}
                        end
                        addTerminalLine("[✓] " .. pkg .. " " .. repo[pkg] .. " installed", colors.green)
                    end
                end
            elseif kind == "remove" then
                if not args[3] then usage(args[1]) return end
                for i = 3, #args do
                    local pkg = args[i]
                    if protectedPackages[pkg] then
                        addTerminalLine("E: " .. pkg .. " is essential and cannot be removed", colors.red)
                    elseif not installed[pkg] then
                        addTerminalLine("E: " .. pkg .. " is not installed", colors.red)
                    else
                        installed[pkg] = nil
                        local bin = getPathObject("/usr/bin")
                        if bin and bin.type == "dir" then bin.children[pkg] = nil end
                        addTerminalLine("[✓] " .. pkg .. " removed", colors.green)
                    end
                end
            elseif kind == "list" then
                for _, pkg in ipairs(sortedKeys(installed)) do
                    addTerminalLine(pkg .. " " .. installed[pkg], colors.text)
                end
            elseif kind == "search" then
                local query = args[3] or ""
                local seen = {}
                for _, source in ipairs({repo, installed}) do
                    for _, pkg in ipairs(sortedKeys(source)) do
                        if not seen[pkg] and pkg:find(query, 1, true) then
                            seen[pkg] = true
                            addTerminalLine(pkg .. " " .. source[pkg] .. (installed[pkg] and "  [installed]" or ""), colors.text)
                        end
                    end
                end
            end
        end,
    }
end

terminalCommands["apt"] = makePackageManager("APT package manager",
    "apt update | upgrade | install <pkg> | remove <pkg> | list | search <text>  (install/remove need root)",
    {update = "update", upgrade = "upgrade", install = "install", remove = "remove", list = "list", search = "search"})
terminalCommands["pacman"] = makePackageManager("Pacman package manager",
    "pacman -Sy | -Syu | -S <pkg> | -R <pkg> | -Q | -Ss <text>  (install/remove need root)",
    {["-Sy"] = "update", ["-Syu"] = "upgrade", ["-S"] = "install", ["-R"] = "remove", ["-Q"] = "list", ["-Ss"] = "search"})

-- ---------- загрузчик с рабочей автозагрузкой ----------
local AUTOBOOT_SECONDS = 5

local function runAutoBoot(seconds)
    bootToken = bootToken + 1
    local token = bootToken
    autoBootActive = true
    local line = addTerminalLine("  Auto-booting in " .. seconds .. "s  (any command cancels)", colors.amber)
    task.spawn(function()
        for remaining = seconds, 1, -1 do
            if bootToken ~= token then return end
            if line then
                line.text = "  Auto-booting in " .. remaining .. "s  (any command cancels)"
                updateTerminalDisplay()
            end
            task.wait(1)
        end
        if bootToken ~= token then return end
        autoBootActive = false
        bootEntry(bootloader.default_entry)
    end)
end

terminalCommands["reboot"] = {
    desc = "Reboot to the bootloader (auto-boots after 5s)",
    action = function()
        while #sshStack > 0 do popSsh() end
        addTerminalLine("🔄 Rebooting system...", colors.amber)
        task.wait(0.5)
        terminalLines = {}
        showBootloader()
        runAutoBoot(AUTOBOOT_SECONDS)
    end,
}

terminalCommands["shutdown"] = {
    desc = "Save and power off (closes the terminal)",
    action = function()
        while #sshStack > 0 do popSsh() end
        addTerminalLine("⏹️ Shutting down system...", colors.amber)
        task.wait(0.5)
        if saveState then saveState(true) end
        addTerminalLine("[✓] System powered off!", colors.green)
        if closeDesktop and desktopGui then closeDesktop() end
        setTerminalActive(false)
    end,
}

local function bootMenuAction()
    showBootloader()
    addTerminalLine("  (auto-boot is only used after 'reboot')", colors.gray)
end
terminalCommands["boot"] = {desc = "Show the bootloader menu", action = bootMenuAction}
terminalCommands["menu"] = {desc = "Show the bootloader menu", action = bootMenuAction}

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
    panel.CanQuery = false
    panel.CanTouch = false
    panel.Massless = true      -- панели не утяжеляют персонажа
    panel.Anchored = false
    panel.CFrame = hrp.CFrame * offset
    panel.Parent = panelFolder

    -- ИСПРАВЛЕНО: раньше Part1 присваивался самой панели (ошибка)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = panel
    weld.Part1 = hrp
    weld.Parent = panel

    local highlight = Instance.new("Highlight")
    highlight.FillColor = colors.green
    highlight.FillTransparency = 0.9
    highlight.OutlineColor = colors.green
    highlight.OutlineTransparency = 0.2
    highlight.Parent = panel

    -- Передняя сторона
    local fg = Instance.new("SurfaceGui")
    fg.Face = Enum.NormalId.Front
    fg.AlwaysOnTop = true
    fg.CanvasSize = Vector2.new(650, 450)
    fg.BackgroundColor3 = colors.bg
    fg.Parent = panel

    local logoL = Instance.new("TextLabel")
    logoL.Size = UDim2.new(1, 0, 0.2, 0)
    logoL.BackgroundTransparency = 1
    logoL.TextColor3 = colors.green
    logoL.Font = Enum.Font.GothamBold
    logoL.TextSize = 24
    logoL.Text = logo
    logoL.TextXAlignment = Enum.TextXAlignment.Center
    logoL.Parent = fg

    local infoL = Instance.new("TextLabel")
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
    infoL.Parent = fg

    -- Задняя сторона (терминал)
    local bg = Instance.new("SurfaceGui")
    bg.Face = Enum.NormalId.Back
    bg.AlwaysOnTop = true
    bg.CanvasSize = Vector2.new(600, 400)
    bg.BackgroundColor3 = colors.bg
    bg.Parent = panel

    local hdr = Instance.new("TextLabel")
    hdr.Size = UDim2.new(1, 0, 0.06, 0)
    hdr.BackgroundTransparency = 1
    hdr.TextColor3 = colors.green
    hdr.Font = Enum.Font.Code
    hdr.TextSize = 11
    hdr.Text = "╔══ TERMINAL ═══════════════════════════════════════════════════╗"
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.Parent = bg

    local out = Instance.new("TextLabel")
    out.Name = "TerminalOutput"
    out.Size = UDim2.new(0.95, 0, 0.86, 0)
    out.Position = UDim2.new(0.025, 0, 0.07, 0)
    out.BackgroundTransparency = 1
    out.TextColor3 = colors.text
    out.Font = Enum.Font.Code
    out.TextSize = 11
    out.TextWrapped = true
    out.RichText = true
    out.TextYAlignment = Enum.TextYAlignment.Top
    out.TextXAlignment = Enum.TextXAlignment.Left
    out.Text = ""
    out.Parent = bg

    local ftr = Instance.new("TextLabel")
    ftr.Size = UDim2.new(1, 0, 0.04, 0)
    ftr.Position = UDim2.new(0, 0, 0.96, 0)
    ftr.BackgroundTransparency = 1
    ftr.TextColor3 = colors.green
    ftr.Font = Enum.Font.Code
    ftr.TextSize = 11
    ftr.Text = "╚════════════════════════════════════════════════════════════════╝"
    ftr.TextXAlignment = Enum.TextXAlignment.Left
    ftr.Parent = bg

    -- Кэшируем лейбл терминала, чтобы не обходить GetChildren() при каждом обновлении
    table.insert(terminalLabels, out)
    return infoL
end

-- Логотипы
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

-- ============================================================
-- ===== 13. ПЕРСОНАЖ, ЭФФЕКТЫ И МОНИТОРИНГ =====
-- ============================================================
local FLY_SPEED = 50
local flyAttachment, flyVelocity, flyAlign
local originalTransparency = {}
local panelsVisible = true

local function onoff(v)
    return v and "🟢 ON" or "🔴 OFF"
end

local function stopFly()
    state.fly = false
    if flyVelocity then flyVelocity:Destroy() end
    if flyAlign then flyAlign:Destroy() end
    if flyAttachment then flyAttachment:Destroy() end
    flyVelocity, flyAlign, flyAttachment = nil, nil, nil
    if hum and hum.Parent then hum.PlatformStand = false end
end

local function startFly()
    state.fly = true
    flyAttachment = Instance.new("Attachment")
    flyAttachment.Parent = hrp

    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.MaxForce = math.huge
    flyVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    flyVelocity.Parent = hrp

    -- держит персонажа вертикально, пока PlatformStand отключает стандартное управление
    flyAlign = Instance.new("AlignOrientation")
    flyAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyAlign.Attachment0 = flyAttachment
    flyAlign.RigidityEnabled = true
    flyAlign.CFrame = hrp.CFrame.Rotation
    flyAlign.Parent = hrp

    hum.PlatformStand = true
end

local function setNoclip(on)
    state.noclip = on
    if not on and player.Character then
        -- Humanoid сам вернёт коллизии остальным частям; восстанавливаем основные
        for _, name in ipairs({"HumanoidRootPart", "Head", "Torso", "UpperTorso", "LowerTorso"}) do
            local part = player.Character:FindFirstChild(name)
            if part then part.CanCollide = true end
        end
    end
end

local function setInvisible(on)
    state.invis = on
    local char = player.Character
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Decal") then
            if on then
                if originalTransparency[obj] == nil then
                    originalTransparency[obj] = obj.Transparency
                end
                obj.Transparency = 1
            else
                -- ИСПРАВЛЕНО: возвращаем исходную прозрачность (HumanoidRootPart раньше становился видимым)
                local orig = originalTransparency[obj]
                if orig ~= nil then obj.Transparency = orig end
            end
        end
    end
    if not on then originalTransparency = {} end
end

local function setGod(on)
    state.god = on
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not on)
    hum.BreakJointsOnDeath = not on
end

local function setPanelsVisible(visible)
    if not panelFolder then return end
    for _, p in ipairs(panelFolder:GetChildren()) do
        p.Transparency = visible and 0 or 1
        for _, child in ipairs(p:GetChildren()) do
            if child:IsA("SurfaceGui") or child:IsA("Highlight") then
                child.Enabled = visible
            end
        end
    end
end

-- Полёт: движение по направлению камеры (W/A/S/D, Space вверх, Ctrl вниз)
runService.RenderStepped:Connect(function()
    if not state.fly or not flyVelocity or not flyVelocity.Parent then return end
    local cam = workspace.CurrentCamera
    local move = Vector3.new(0, 0, 0)
    if not terminalActive then
        if uis:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
    end
    if move.Magnitude > 0 then move = move.Unit end
    flyVelocity.VectorVelocity = move * FLY_SPEED * state.speed

    local look = cam.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flyAlign and flat.Magnitude > 0.01 then
        flyAlign.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), flat)
    end
end)

-- Noclip: Roblox каждый шаг физики возвращает CanCollide, поэтому отключаем его в Stepped
runService.Stepped:Connect(function()
    if not state.noclip then return end
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end)

-- Создание панелей для нового персонажа (вызывается при каждом респауне)
local function setupCharacter(char)
    -- сбрасываем эффекты прошлого персонажа
    state.fly, state.god, state.noclip, state.invis, state.speed = false, false, false, false, 1
    originalTransparency = {}
    flyVelocity, flyAlign, flyAttachment = nil, nil, nil

    hrp = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    baseWalkSpeed = hum.WalkSpeed

    -- ИСПРАВЛЕНО: старые панели лежат в папке MDPanels, её и удаляем (в том числе от прошлого запуска скрипта)
    local old = workspace:FindFirstChild("MDPanels")
    if old then old:Destroy() end
    panelFolder = Instance.new("Folder")
    panelFolder.Name = "MDPanels"
    panelFolder.Parent = workspace

    terminalLabels = {}
    i1 = createPanel("MDPanel_Kali", CFrame.new(-7.0, 2.0, -5.0) * CFrame.Angles(0, math.rad(25), 0), "🦞 KALI LINUX", l1 .. "\n\n[STATUS]: LOADING...")
    i2 = createPanel("MDPanel_Arch", CFrame.new(0, 2.0, -6.0) * CFrame.Angles(0, math.rad(180), 0), "🐧 ARCH LINUX", l2 .. "\n\n[STATUS]: LOADING...")
    i3 = createPanel("MDPanel_BlackArch", CFrame.new(7.0, 2.0, -5.0) * CFrame.Angles(0, math.rad(-25), 0), "💀 BLACKARCH", l3 .. "\n\n[STATUS]: LOADING...")
    updateTerminalDisplay()
end

-- Мониторинг: FPS считаем каждый кадр, текст панелей обновляем 5 раз в секунду
local accum = 0
monitorConnection = runService.Heartbeat:Connect(function(dt)
    if not hrp or not hrp.Parent or not hum or not hum.Parent then return end

    frameCount = frameCount + 1
    if tick() - lastFpsUpdate >= 1 then
        fps = frameCount
        frameCount = 0
        lastFpsUpdate = tick()
    end

    if state.god and hum.Health < hum.MaxHealth then
        hum.Health = hum.MaxHealth
    end

    accum = accum + dt
    if accum < 0.2 then return end
    accum = 0

    local time = os.date("%H:%M:%S")
    local health = math.floor(hum.Health)
    local maxHealth = hum.MaxHealth
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
]], x, y, z, onoff(state.fly), onoff(state.god))
    end

    if i3 and i3.Parent then
        i3.Text = l3 .. string.format([[
[STATUS]: ACTIVE
[NOCLIP]: %s
[INVIS]: %s
[SPEED]: x%d
]], onoff(state.noclip), onoff(state.invis), state.speed)
    end
end)


-- ============================================================
-- ===== 13b. ТЕМЫ ОФОРМЛЕНИЯ =====
-- ============================================================
applyTheme = function(name)
    local theme = themes[name]
    if not theme then return false end

    -- карта "цвет -> имя" для старой темы
    local old = {}
    for key, c in pairs(colors) do old[c:ToHex()] = key end
    for key, c in pairs(theme) do colors[key] = c end

    for _, line in ipairs(terminalLines) do
        local key = old[line.color:ToHex()]
        if key then line.color = colors[key] end
    end

    local function remap(c)
        local key = old[c:ToHex()]
        return key and colors[key] or c
    end
    local function recolor(container)
        if not container then return end
        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                d.TextColor3 = remap(d.TextColor3)
            elseif d:IsA("UIStroke") then
                d.Color = remap(d.Color)
            elseif d:IsA("Highlight") then
                d.FillColor = remap(d.FillColor)
                d.OutlineColor = remap(d.OutlineColor)
            end
        end
    end
    recolor(panelFolder)
    recolor(desktopGui)

    currentThemeName = name
    updateTerminalDisplay()
    return true
end

-- ============================================================
-- ===== 13c. РАБОЧИЙ СТОЛ (startx / wayland) =====
-- ============================================================
local desktopRoot
local zCounter = 10

local function mk(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function makeWindow(title, size, position)
    zCounter = zCounter + 1
    local win = mk("Frame", {
        Size = size, Position = position, BackgroundColor3 = Color3.fromRGB(14, 18, 22),
        BorderSizePixel = 0, ZIndex = zCounter, Active = true,
    }, desktopRoot)
    mk("UIStroke", {Color = colors.green, Thickness = 1}, win)

    local bar = mk("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Color3.fromRGB(26, 34, 30), BorderSizePixel = 0}, win)
    mk("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = "  " .. title,
        TextColor3 = colors.green, Font = Enum.Font.Code, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    }, bar)
    local close = mk("TextButton", {
        Size = UDim2.new(0, 26, 1, 0), Position = UDim2.new(1, -26, 0, 0), BackgroundTransparency = 1,
        Text = "✕", TextColor3 = colors.red, Font = Enum.Font.Code, TextSize = 14,
    }, bar)
    close.Activated:Connect(function() win:Destroy() end)

    local dragging, dragStart, startPos = false, nil, nil
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
            zCounter = zCounter + 1
            win.ZIndex = zCounter
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local moveConn = uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    win.Destroying:Connect(function() moveConn:Disconnect() end)

    local content = mk("Frame", {Size = UDim2.new(1, 0, 1, -26), Position = UDim2.new(0, 0, 0, 26), BackgroundTransparency = 1}, win)
    return win, content
end

local function openViewer(path)
    local node = getPathObject(path)
    if not node or node.type ~= "file" then return end
    local text = hasPerm(node, "r") and (node.content or "") or "⛔ Permission denied"
    if text == "" then text = "(empty file)" end
    local _, content = makeWindow("📄 " .. (path:match("([^/]+)$") or path), UDim2.fromOffset(360, 260),
        UDim2.fromOffset(220 + math.random(0, 80), 90 + math.random(0, 60)))
    local scroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
    }, content)
    mk("TextLabel", {
        Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Text = text, TextColor3 = colors.text, Font = Enum.Font.Code, TextSize = 14, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    }, scroll)
end

local function openFiles()
    local _, content = makeWindow("📁 Files", UDim2.fromOffset(380, 300), UDim2.fromOffset(130, 50))
    local pathLabel = mk("TextLabel", {
        Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 2), BackgroundTransparency = 1,
        Text = "", TextColor3 = colors.cyan, Font = Enum.Font.Code, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    }, content)
    local list = mk("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -30), Position = UDim2.fromOffset(4, 26), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
    }, content)
    mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)

    local path = currentPath
    local refresh
    refresh = function(target)
        local node, why = getPathObject(target)
        if why == "denied" or not node or node.type ~= "dir" or not hasPerm(node, "r") then
            pathLabel.Text = "⛔ " .. resolvePath(target)
            return
        end
        path = resolvePath(target)
        pathLabel.Text = path
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local order = 0
        local function addRow(text, color, onClick)
            order = order + 1
            local btn = mk("TextButton", {
                Size = UDim2.new(1, -6, 0, 24), BackgroundTransparency = 1, Text = text, TextColor3 = color,
                Font = Enum.Font.Code, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order,
            }, list)
            btn.Activated:Connect(onClick)
        end
        if path ~= "/" then
            addRow("📁 ..", colors.gray, function() refresh(path .. "/..") end)
        end
        for _, name in ipairs(sortedKeys(node.children)) do
            local child = node.children[name]
            local isDir = child.type == "dir"
            addRow((isDir and "📁 " or "📄 ") .. name .. "   " .. permString(child), isDir and colors.cyan or colors.text, function()
                local full = (path == "/" and "" or path) .. "/" .. name
                if isDir then refresh(full) else openViewer(full) end
            end)
        end
    end
    refresh(path)
end

local function openClock()
    local win, content = makeWindow("🕒 Clock", UDim2.fromOffset(240, 120), UDim2.fromOffset(180, 80))
    local label = mk("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", TextColor3 = colors.green,
        Font = Enum.Font.Code, TextSize = 28,
    }, content)
    task.spawn(function()
        while win.Parent do
            label.Text = os.date("%H:%M:%S") .. "\n" .. os.date("%Y-%m-%d")
            task.wait(0.5)
        end
    end)
end

local function openMonitor()
    local win, content = makeWindow("📊 Monitor", UDim2.fromOffset(320, 240), UDim2.fromOffset(240, 120))
    local label = mk("TextLabel", {
        Size = UDim2.new(1, -12, 1, -8), Position = UDim2.fromOffset(6, 4), BackgroundTransparency = 1, Text = "",
        TextColor3 = colors.text, Font = Enum.Font.Code, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, content)
    task.spawn(function()
        while win.Parent do
            local ping, mem = getPingMs(), getMemoryMb()
            local lines = {
                "FPS:      " .. fps,
                "Ping:     " .. (ping and (ping .. " ms") or "n/a"),
                "Players:  " .. #game.Players:GetPlayers(),
                "Memory:   " .. (mem and (mem .. " MB") or "n/a"),
                "Uptime:   " .. uptimeString(),
                "",
                "PID  COMMAND",
            }
            for i, proc in ipairs(kernel.processes) do
                if i > 7 then break end
                lines[#lines + 1] = string.format("%-4d %s", proc.pid, proc.name)
            end
            label.Text = table.concat(lines, "\n")
            task.wait(0.5)
        end
    end)
end

local function openNotes()
    local _, content = makeWindow("📝 Notes", UDim2.fromOffset(320, 220), UDim2.fromOffset(280, 160))
    mk("TextBox", {
        Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Type notes here...", TextColor3 = colors.text, PlaceholderColor3 = colors.gray,
        Font = Enum.Font.Code, TextSize = 14, MultiLine = true, ClearTextOnFocus = false, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    }, content)
end

openDesktop = function(kind)
    if desktopGui then
        addTerminalLine("ℹ️ Desktop already running (stopx to exit)", colors.amber)
        return
    end
    addTerminalLine("🖥️ Starting " .. kind .. " graphical interface...", colors.green)
    task.wait(0.5)

    local gui = mk("ScreenGui", {Name = "OutpostDesktop", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5}, player:WaitForChild("PlayerGui"))
    desktopGui = gui
    desktopRoot = mk("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 10, 12), BackgroundTransparency = 0.1, BorderSizePixel = 0,
    }, gui)
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromScale(0, 0.42), BackgroundTransparency = 1,
        Text = kind .. " · OUTPOST 3 LINUX", TextColor3 = colors.green, TextTransparency = 0.7,
        Font = Enum.Font.GothamBold, TextSize = 40,
    }, desktopRoot)

    local apps = {
        {"📁\nFiles", openFiles}, {"🕒\nClock", openClock}, {"📊\nMonitor", openMonitor}, {"📝\nNotes", openNotes},
    }
    for i, app in ipairs(apps) do
        local icon = mk("TextButton", {
            Size = UDim2.fromOffset(84, 70), Position = UDim2.fromOffset(16, 16 + (i - 1) * 80),
            BackgroundColor3 = Color3.fromRGB(18, 24, 26), BackgroundTransparency = 0.2, Text = app[1],
            TextColor3 = colors.text, Font = Enum.Font.Code, TextSize = 16,
        }, desktopRoot)
        mk("UIStroke", {Color = colors.green, Thickness = 1, Transparency = 0.6}, icon)
        icon.Activated:Connect(app[2])
    end

    local bar = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 1, -36), BackgroundColor3 = Color3.fromRGB(16, 22, 24),
        BorderSizePixel = 0, ZIndex = 100000,
    }, desktopRoot)
    local exitButton = mk("TextButton", {
        Size = UDim2.fromOffset(150, 36), BackgroundTransparency = 1, Text = "⏻ Exit " .. kind,
        TextColor3 = colors.red, Font = Enum.Font.Code, TextSize = 16, ZIndex = 100001,
    }, bar)
    exitButton.Activated:Connect(function() closeDesktop() end)
    local clock = mk("TextLabel", {
        Size = UDim2.fromOffset(160, 36), Position = UDim2.new(1, -170, 0, 0), BackgroundTransparency = 1, Text = "",
        TextColor3 = colors.green, Font = Enum.Font.Code, TextSize = 16, ZIndex = 100001,
    }, bar)
    task.spawn(function()
        while gui.Parent do
            clock.Text = os.date("%H:%M:%S")
            task.wait(1)
        end
    end)

    -- освобождаем клавиатуру, чтобы можно было пользоваться мышью и Notes
    setTerminalActive(false)
    addTerminalLine("✅ Desktop started — click icons, drag windows by the title bar", colors.green)
end

closeDesktop = function()
    if not desktopGui then
        addTerminalLine("ℹ️ Desktop is not running", colors.gray)
        return
    end
    desktopGui:Destroy()
    desktopGui = nil
    desktopRoot = nil
    addTerminalLine("🖥️ Desktop stopped", colors.green)
end

-- ============================================================
-- ===== 14. ВВОД ТЕРМИНАЛА (скрытый TextBox) =====
-- ============================================================
screenGui = Instance.new("ScreenGui")
screenGui.Name = "OutpostInput"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.fromOffset(1, 1)
inputBox.BackgroundTransparency = 1
inputBox.TextTransparency = 1
inputBox.ClearTextOnFocus = false
inputBox.Text = ""
inputBox.Parent = screenGui

local function runCommand(line)
    if busy then return end
    line = trim(line)
    if line == "" then return end

    table.insert(commandHistory, line)
    historyIndex = #commandHistory + 1
    scrollOffset = 0
    addTerminalLine(getPrompt() .. line, colors.text)

    busy = true -- команды с task.wait не перемешиваются между собой
    local ok, err = pcall(executeLine, line)
    busy = false
    renderSuspended = false
    captureBuffer = nil
    if not ok then
        addTerminalLine("❌ Error: " .. tostring(err), colors.red)
    end
    updateTerminalDisplay()
end

setTerminalActive = function(active)
    terminalActive = active
    if active then
        scrollOffset = 0
        addTerminalLine(string.rep("─", 51), colors.gray)
        addTerminalLine("🖥️ TERMINAL ACTIVATED", colors.green)
        addTerminalLine("'help' = commands | Tab = autocomplete (empty line: exit)", colors.gray)
        addTerminalLine(string.rep("─", 51), colors.gray)
        task.defer(function()
            if terminalActive then inputBox:CaptureFocus() end
        end)
    else
        if pendingPrompt then inputEvent:Fire(nil) end
        inputBox:ReleaseFocus()
        inputBox.Text = ""
        currentInput = ""
        updateTerminalDisplay()
    end
end

-- Автодополнение: команды (первое слово) и пути (остальные)
local function completeInput(text)
    local prefixText, word = text:match("^(.*%s)(%S*)$")
    if not prefixText then prefixText, word = "", text end
    local candidates = {}
    if prefixText == "" then
        for name in pairs(terminalCommands) do
            if name:sub(1, #word) == word then candidates[#candidates + 1] = name end
        end
        for name in pairs(aliases) do
            if name:sub(1, #word) == word then candidates[#candidates + 1] = name end
        end
    else
        local dirPart, namePart = word:match("^(.*/)([^/]*)$")
        if not dirPart then dirPart, namePart = "", word end
        local dirNode = getPathObject(dirPart == "" and "." or dirPart)
        if dirNode and dirNode.type == "dir" and hasPerm(dirNode, "r") then
            for name, child in pairs(dirNode.children) do
                if name:sub(1, #namePart) == namePart and (namePart ~= "" or name:sub(1, 1) ~= ".") then
                    candidates[#candidates + 1] = dirPart .. name .. (child.type == "dir" and "/" or "")
                end
            end
        end
    end
    table.sort(candidates)
    if #candidates == 0 then return text end
    if #candidates == 1 then
        return prefixText .. candidates[1] .. (prefixText == "" and " " or "")
    end
    local common = candidates[1]
    for _, c in ipairs(candidates) do
        while c:sub(1, #common) ~= common do common = common:sub(1, -2) end
    end
    local shown = {}
    for i = 1, math.min(#candidates, 12) do shown[i] = candidates[i] end
    addTerminalLine(table.concat(shown, "  ") .. (#candidates > 12 and "  ..." or ""), colors.gray)
    return prefixText .. common
end

inputBox:GetPropertyChangedSignal("Text"):Connect(function()
    local clean = (inputBox.Text:gsub("[\t\r\n]", ""))
    if clean ~= inputBox.Text then
        inputBox.Text = clean -- убираем случайно попавший символ Tab
        return
    end
    currentInput = inputBox.Text
    scrollOffset = 0
    updateTerminalDisplay()
end)

inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local line = inputBox.Text
        inputBox.Text = ""
        currentInput = ""
        if pendingPrompt then
            inputEvent:Fire(line)          -- ответ на запрос пароля / редактора
        elseif busy then
            interruptFlag = true           -- Enter во время работы команды её прерывает
        else
            task.spawn(runCommand, line)
        end
        updateTerminalDisplay()
    end
    -- при открытом рабочем столе фокус не возвращаем (иначе нельзя печатать в Notes)
    if terminalActive and not desktopGui then
        task.defer(function()
            if terminalActive and not desktopGui then inputBox:CaptureFocus() end
        end)
    end
end)

uis.InputBegan:Connect(function(input, gp)
    local key = input.KeyCode

    -- Tab работает и тогда, когда фокус в TextBox (там gp = true)
    if key == Enum.KeyCode.Tab and (not gp or terminalActive) then
        if terminalActive and pendingPrompt then
            inputEvent:Fire(nil)           -- Tab отменяет запрос
            return
        end
        if terminalActive and currentInput ~= "" then
            local typed = currentInput
            task.defer(function()
                local completed = completeInput(typed)
                inputBox.Text = completed
                inputBox.CursorPosition = #completed + 1
            end)
            return
        end
        setTerminalActive(not terminalActive)
        return
    end

    if not terminalActive then return end

    local ctrl = uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.RightControl)
    if key == Enum.KeyCode.C and ctrl then
        if pendingPrompt then
            inputEvent:Fire(nil)
        elseif busy then
            interruptFlag = true
            addTerminalLine("^C", colors.gray)
        end
        return
    end

    if key == Enum.KeyCode.Up then
        if historyIndex > 1 and not pendingPrompt then
            historyIndex = historyIndex - 1
            inputBox.Text = commandHistory[historyIndex]
            inputBox.CursorPosition = #inputBox.Text + 1
        end
    elseif key == Enum.KeyCode.Down then
        if not pendingPrompt then
            if historyIndex < #commandHistory then
                historyIndex = historyIndex + 1
                inputBox.Text = commandHistory[historyIndex]
            else
                historyIndex = #commandHistory + 1
                inputBox.Text = ""
            end
            inputBox.CursorPosition = #inputBox.Text + 1
        end
    elseif key == Enum.KeyCode.PageUp then
        scrollOffset = scrollOffset + 8
        updateTerminalDisplay()
    elseif key == Enum.KeyCode.PageDown then
        scrollOffset = math.max(0, scrollOffset - 8)
        updateTerminalDisplay()
    elseif key == Enum.KeyCode.End then
        scrollOffset = 0
        updateTerminalDisplay()
    end
end)

-- ============================================================
-- ===== 14b. СОХРАНЕНИЕ И ЗАГРУЗКА СОСТОЯНИЯ (через сервер) =====
-- ============================================================
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local autosaveEnabled = false

saveState = function(quiet)
    local remote = ReplicatedStorage:FindFirstChild("Outpost3Save")
    if not remote then
        if not quiet then
            addTerminalLine("⚠️ Save server not found. Put Outpost3Save.server.lua into ServerScriptService.", colors.amber)
        end
        return false
    end
    -- сохраняем свою машину (а не ssh-сессию)
    local localFs, localUsers = fileSystem, users
    if #sshStack > 0 then localFs, localUsers = sshStack[1].fs, sshStack[1].users end
    local okEncode, payload = pcall(function()
        return HttpService:JSONEncode({
            v = 1, fs = localFs, users = localUsers, env = env, aliases = aliases,
            theme = currentThemeName, installed = installed,
        })
    end)
    if not okEncode then
        if not quiet then addTerminalLine("❌ Cannot encode state", colors.red) end
        return false
    end
    if #payload > 190000 then
        if not quiet then addTerminalLine("❌ State is too large to save (" .. #payload .. " bytes)", colors.red) end
        return false
    end
    local okCall, ok, msg = pcall(function() return remote:InvokeServer("save", payload) end)
    if not okCall or not ok then
        if not quiet then addTerminalLine("❌ Save failed: " .. tostring(okCall and msg or ok), colors.red) end
        return false
    end
    return true
end

loadState = function(quiet)
    if #sshStack > 0 then
        if not quiet then addTerminalLine("❌ Close the ssh session first (exit)", colors.red) end
        return false
    end
    local remote = ReplicatedStorage:FindFirstChild("Outpost3Save")
    if not remote then
        if not quiet then addTerminalLine("⚠️ Save server not found (see Outpost3Save.server.lua)", colors.amber) end
        return false
    end
    local okCall, data = pcall(function() return remote:InvokeServer("load") end)
    if not okCall then
        if not quiet then addTerminalLine("❌ Load failed", colors.red) end
        return false
    end
    autosaveEnabled = true
    if type(data) ~= "string" then
        if not quiet then addTerminalLine("ℹ️ No saved state yet — use 'save'", colors.gray) end
        return false
    end
    local okDecode, saved = pcall(function() return HttpService:JSONDecode(data) end)
    if not okDecode or type(saved) ~= "table" or type(saved.fs) ~= "table" or type(saved.fs["/"]) ~= "table"
        or type(saved.users) ~= "table" or #saved.users < 1 then
        if not quiet then addTerminalLine("❌ Saved state is corrupted", colors.red) end
        return false
    end

    local keepName = currentUser.name
    fileSystem = saved.fs
    users = saved.users
    currentUser = nil
    for _, u in ipairs(users) do
        if u.name == keepName then currentUser = u end
    end
    currentUser = currentUser or users[2] or users[1]
    isRoot = currentUser.is_root == true
    currentPath = homeOf(currentUser)
    if not getPathObject(currentPath) then currentPath = "/" end
    if type(saved.env) == "table" then env = saved.env end
    if type(saved.aliases) == "table" then aliases = saved.aliases end
    if type(saved.installed) == "table" then installed = saved.installed end
    if saved.theme and themes[saved.theme] then applyTheme(saved.theme) end
    return true
end

-- ============================================================
-- ===== 15. ГОРЯЧИЕ КЛАВИШИ =====
-- ============================================================
uis.InputBegan:Connect(function(input, gp)
    -- ИСПРАВЛЕНО: при активном терминале хоткеи не срабатывают
    if gp or terminalActive then return end
    if not hum or not hum.Parent then return end
    local k = input.KeyCode

    if k == Enum.KeyCode.F then
        if state.fly then stopFly() else startFly() end
        addTerminalLine(state.fly and "🕊️ Fly ON" or "🕊️ Fly OFF", state.fly and colors.green or colors.red)
    elseif k == Enum.KeyCode.G then
        setGod(not state.god)
        addTerminalLine(state.god and "🛡️ God ON" or "🛡️ God OFF", colors.amber)
    elseif k == Enum.KeyCode.N then
        setNoclip(not state.noclip)
        addTerminalLine(state.noclip and "🧱 Noclip ON" or "🧱 Noclip OFF", colors.purple)
    elseif k == Enum.KeyCode.I then
        setInvisible(not state.invis)
        addTerminalLine(state.invis and "👁️ Invisible ON" or "👁️ Invisible OFF", colors.gray)
    elseif k == Enum.KeyCode.S and uis:IsKeyDown(Enum.KeyCode.LeftShift) then
        state.speed = state.speed == 1 and 2 or 1
        hum.WalkSpeed = baseWalkSpeed * state.speed
        addTerminalLine("🏃 Speed x" .. state.speed, colors.green)
    elseif k == Enum.KeyCode.H then
        hum.Health = hum.MaxHealth
        addTerminalLine("❤️ Healed!", colors.red)
    elseif k == Enum.KeyCode.P then
        -- ИСПРАВЛЕНО: Esc обрабатывается Roblox (gp = true), поэтому скрытие панелей перенесено на P
        panelsVisible = not panelsVisible
        setPanelsVisible(panelsVisible)
    end
end)


-- ============================================================
-- ===== 16. ЗАПУСК И ПРИВЕТСТВИЕ =====
-- ============================================================
-- Панели пересоздаются при каждом респауне
player.CharacterAdded:Connect(setupCharacter)
setupCharacter(player.Character or player.CharacterAdded:Wait())

-- Системные процессы, окружение и алиасы по умолчанию (как в ~/.bashrc)
createSystemProcesses()
env.PATH = "/usr/local/bin:/usr/bin:/bin"
env.LANG = "en_US.UTF-8"
env.TERM = "xterm-256color"
env.EDITOR = "nano"
aliases.ll = "ls -la"
aliases.la = "ls -a"

local function pad(s, width)
    return s .. string.rep(" ", math.max(0, width - (utf8.len(s) or #s)))
end
local BANNER_W = 52
local function bannerLine(s)
    addTerminalLine("║ " .. pad(s, BANNER_W) .. " ║", colors.green)
end

task.wait(0.5)
addTerminalLine("╔" .. string.rep("═", BANNER_W + 2) .. "╗", colors.green)
bannerLine("🦞 OUTPOST 3 LINUX v" .. kernel.version)
bannerLine("Kernel: JCJ_KERNEL " .. kernel.version)
bannerLine("Bootloader: JCJ_BOOTLOADER v" .. bootloader.version)
bannerLine("Press TAB to open terminal, 'help' for commands")
bannerLine("User: Yahmyh78 (password 12345), root: toor")
bannerLine("Hotkeys: F-G-N-I, Shift+S, H, P (hide panels)")
addTerminalLine("╚" .. string.rep("═", BANNER_W + 2) .. "╝", colors.green)

print("🦞 OUTPOST 3 LINUX LOADED!")
print("  TAB - Open/close terminal (with text: autocomplete)")
print("  F - Fly | G - God | N - Noclip | I - Invisible")
print("  Shift+S - Speed | H - Heal | P - Hide/Show panels")

-- Загрузка сохранённого состояния и автосохранение (нужен Outpost3Save.server.lua)
task.spawn(function()
    task.wait(1)
    if loadState(true) then
        addTerminalLine("💾 Saved state restored", colors.green)
    end
end)
task.spawn(function()
    while true do
        task.wait(120)
        if autosaveEnabled and #sshStack == 0 then saveState(true) end
    end
end)
