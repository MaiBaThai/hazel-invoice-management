import os
import re

project_path = "ios/Runner.xcodeproj/project.pbxproj"
team_id = "SGSV6FFW8J"

if not os.path.exists(project_path):
    print(f"Error: {project_path} not found.")
    exit(1)

with open(project_path, "r") as f:
    content = f.read()

# Configurations to configure
configs = {
    # Project Configs
    "97C147031CF9000F007D117D": ("Debug-dev", "debug"),
    "97C147031CF9000F007E117D": ("Debug-prod", "debug"),
    "97C147041CF9000F007D117D": ("Release-dev", "release"),
    "97C147041CF9000F007E117D": ("Release-prod", "release"),
    "249021D3217E4FDB00AD95B9": ("Profile-dev", "profile"),
    "249021D3217E4FDB00AC95B9": ("Profile-prod", "profile"),
    # Runner Target Configs
    "97C147061CF9000F007D117D": ("Debug-dev", "debug"),
    "97C147061CF9000F007E117D": ("Debug-prod", "debug"),
    "97C147071CF9000F007D117D": ("Release-dev", "release"),
    "97C147071CF9000F007E117D": ("Release-prod", "release"),
    "249021D4217E4FDB00AD95B9": ("Profile-dev", "profile"),
    "249021D4217E4FDB00AC95B9": ("Profile-prod", "profile"),
    # RunnerTests Target Configs
    "331C8088294A63A400273BE5": ("Debug-dev", "debug"),
    "331C8088294A63A400283BE5": ("Debug-prod", "debug"),
    "331C8089294A63A400273BE5": ("Release-dev", "release"),
    "331C8089294A63A400283BE5": ("Release-prod", "release"),
    "331C808A294A63A400273BE5": ("Profile-dev", "profile"),
    "331C808A294A63A400283BE5": ("Profile-prod", "profile")
}

for uuid, (name, config_type) in configs.items():
    # Find the block for this configuration UUID
    pattern = r"(" + uuid + r" /\* [^*]+ \*/ = \{\n(?:[^\n]*\n)*?\t\t\};)"
    match = re.search(pattern, content)
    if match:
        full_block = match.group(1)
        new_block = full_block

        # 1. Ensure DEVELOPMENT_TEAM is set
        if "DEVELOPMENT_TEAM" not in new_block:
            build_settings_start = r"(buildSettings = \{)"
            bs_match = re.search(build_settings_start, new_block)
            if bs_match:
                new_block = new_block.replace(
                    bs_match.group(1),
                    f"buildSettings = {{\n\t\t\t\tDEVELOPMENT_TEAM = {team_id};"
                )

        # 2. Ensure CODE_SIGN_STYLE is set to Automatic
        if "CODE_SIGN_STYLE" not in new_block:
            build_settings_start = r"(buildSettings = \{)"
            bs_match = re.search(build_settings_start, new_block)
            if bs_match:
                new_block = new_block.replace(
                    bs_match.group(1),
                    f"buildSettings = {{\n\t\t\t\tCODE_SIGN_STYLE = Automatic;"
                )

        # 3. Restore iPhone Developer identity for all configs to match automatic signing style
        identity_val = "iPhone Developer"
        
        identity_pattern = r'("CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "[^"]+";)'
        ident_match = re.search(identity_pattern, new_block)
        if ident_match:
            new_block = new_block.replace(
                ident_match.group(1),
                f'"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "{identity_val}";'
            )
        else:
            build_settings_start = r"(buildSettings = \{)"
            bs_match = re.search(build_settings_start, new_block)
            if bs_match:
                new_block = new_block.replace(
                    bs_match.group(1),
                    f'buildSettings = {{\n\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "{identity_val}";'
                )

        # Update file content if changed
        if new_block != full_block:
            content = content.replace(full_block, new_block)

with open(project_path, "w") as f:
    f.write(content)

print("Successfully restored signing configurations to automatic developer signing.")
