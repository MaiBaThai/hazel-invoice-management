import re
import os

project_path = "ios/Runner.xcodeproj/project.pbxproj"

if not os.path.exists(project_path):
    print(f"Error: {project_path} not found.")
    exit(1)

with open(project_path, "r") as f:
    content = f.read()

# 1. Update IPHONEOS_DEPLOYMENT_TARGET to 15.0 globally to support cloud_firestore
content = content.replace("IPHONEOS_DEPLOYMENT_TARGET = 13.0;", "IPHONEOS_DEPLOYMENT_TARGET = 15.0;")

# 2. Update PBXFileReference for Info.plist -> Info-dev.plist & Info-prod.plist
old_ref = '97C147021CF9000F007C117D /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };'
new_refs = (
    '97C147021CF9000F007C117D /* Info-dev.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info-dev.plist"; sourceTree = "<group>"; };\n'
    '\t\t97C147021CF9000F007C117E /* Info-prod.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info-prod.plist"; sourceTree = "<group>"; };'
)
content = content.replace(old_ref, new_refs)

# 3. Update Runner PBXGroup children
old_group = (
    '\t\t\tchildren = (\n'
    '\t\t\t\t97C146FA1CF9000F007C117D /* Main.storyboard */,\n'
    '\t\t\t\t97C146FD1CF9000F007C117D /* Assets.xcassets */,\n'
    '\t\t\t\t97C146FF1CF9000F007C117D /* LaunchScreen.storyboard */,\n'
    '\t\t\t\t97C147021CF9000F007C117D /* Info.plist */,'
)
new_group = (
    '\t\t\tchildren = (\n'
    '\t\t\t\t97C146FA1CF9000F007C117D /* Main.storyboard */,\n'
    '\t\t\t\t97C146FD1CF9000F007C117D /* Assets.xcassets */,\n'
    '\t\t\t\t97C146FF1CF9000F007C117D /* LaunchScreen.storyboard */,\n'
    '\t\t\t\t97C147021CF9000F007C117D /* Info-dev.plist */,\n'
    '\t\t\t\t97C147021CF9000F007C117E /* Info-prod.plist */,'
)
content = content.replace(old_group, new_group)

# 4. Add Custom Shell Script Build Phase to PBXShellScriptBuildPhase section
old_build_phase_marker = "/* Begin PBXShellScriptBuildPhase section */"
copy_script = """\t\t9740EEB61CF901F6004384FD /* Copy GoogleService-Info.plist */ = {
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\talwaysOutOfDate = 1;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\tinputPaths = (
\t\t\t);
\t\t\tname = "Copy GoogleService-Info.plist";
\t\t\toutputPaths = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t\tshellPath = /bin/sh;
\t\t\tshellScript = "if [[ \\"$CONFIGURATION\\" == *\\"dev\\"* ]]; then\\n  FLAVOR=\\"dev\\"\\nelif [[ \\"$CONFIGURATION\\" == *\\"prod\\"* ]]; then\\n  FLAVOR=\\"prod\\"\\nelse\\n  FLAVOR=\\"dev\\"\\nfi\\nPLIST_PATH=\\"${PROJECT_DIR}/config/${FLAVOR}/GoogleService-Info.plist\\"\\ncp -f \\"${PLIST_PATH}\\" \\"${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist\\"\\necho \\"Copied GoogleService-Info.plist for flavor: ${FLAVOR}\\"\\ncp -f \\"${PROJECT_DIR}/Runner/Info-${FLAVOR}.plist\\" \\"${PROJECT_DIR}/Runner/Info.plist\\"\\necho \\"Copied Info-${FLAVOR}.plist to Runner/Info.plist\\"\\n";
\t\t};"""

content = content.replace(old_build_phase_marker, f"{old_build_phase_marker}\n{copy_script}")

# 5. Reference Build Phase in Runner PBXNativeTarget buildPhases list
old_native_target = """\t\t97C146ED1CF9000F007C117D /* Runner */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;
\t\t\tbuildPhases = (
\t\t\t\t9740EEB61CF901F6004384FC /* Run Script */,"""

new_native_target = """\t\t97C146ED1CF9000F007C117D /* Runner */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;
\t\t\tbuildPhases = (
\t\t\t\t9740EEB61CF901F6004384FD /* Copy GoogleService-Info.plist */,
\t\t\t\t9740EEB61CF901F6004384FC /* Run Script */,"""

content = content.replace(old_native_target, new_native_target)

# 6. Extract and duplicate Build Configurations
configs_to_duplicate = {
    # Project Configs
    "97C147031CF9000F007C117D": ("Debug", "project"),
    "97C147041CF9000F007C117D": ("Release", "project"),
    "249021D3217E4FDB00AE95B9": ("Profile", "project"),
    # Target Runner Configs
    "97C147061CF9000F007C117D": ("Debug", "runner"),
    "97C147071CF9000F007C117D": ("Release", "runner"),
    "249021D4217E4FDB00AE95B9": ("Profile", "runner"),
    # RunnerTests Configs
    "331C8088294A63A400263BE5": ("Debug", "tests"),
    "331C8089294A63A400263BE5": ("Release", "tests"),
    "331C808A294A63A400263BE5": ("Profile", "tests"),
}

uuid_map = {
    "97C147031CF9000F007C117D": {"dev": "97C147031CF9000F007D117D", "prod": "97C147031CF9000F007E117D"},
    "97C147041CF9000F007C117D": {"dev": "97C147041CF9000F007D117D", "prod": "97C147041CF9000F007E117D"},
    "249021D3217E4FDB00AE95B9": {"dev": "249021D3217E4FDB00AD95B9", "prod": "249021D3217E4FDB00AC95B9"},
    "97C147061CF9000F007C117D": {"dev": "97C147061CF9000F007D117D", "prod": "97C147061CF9000F007E117D"},
    "97C147071CF9000F007C117D": {"dev": "97C147071CF9000F007D117D", "prod": "97C147071CF9000F007E117D"},
    "249021D4217E4FDB00AE95B9": {"dev": "249021D4217E4FDB00AD95B9", "prod": "249021D4217E4FDB00AC95B9"},
    "331C8088294A63A400263BE5": {"dev": "331C8088294A63A400273BE5", "prod": "331C8088294A63A400283BE5"},
    "331C8089294A63A400263BE5": {"dev": "331C8089294A63A400273BE5", "prod": "331C8089294A63A400283BE5"},
    "331C808A294A63A400263BE5": {"dev": "331C808A294A63A400273BE5", "prod": "331C808A294A63A400283BE5"},
}

new_configs = []

for uuid, (base_name, config_type) in configs_to_duplicate.items():
    # Use a flexible regex to grab the entire block for this uuid
    # It starts with \t\t[uuid] /* name */ = { and matches until the closing \t\t};
    regex_for_uuid = r"(\t\t" + uuid + r" /\* [^*]+ \*/ = \{\n(?:[^\n]*\n)*?\t\t\};)"
    match = re.search(regex_for_uuid, content)
    
    if match:
        full_block = match.group(1)
        
        # Build dev config
        dev_uuid = uuid_map[uuid]["dev"]
        dev_block = full_block.replace(uuid, dev_uuid)
        dev_block = dev_block.replace(f"/* {base_name} */", f"/* {base_name}-dev */")
        dev_block = dev_block.replace(f"name = {base_name};", f"name = \"{base_name}-dev\";")
        
        # Build prod config
        prod_uuid = uuid_map[uuid]["prod"]
        prod_block = full_block.replace(uuid, prod_uuid)
        prod_block = prod_block.replace(f"/* {base_name} */", f"/* {base_name}-prod */")
        prod_block = prod_block.replace(f"name = {base_name};", f"name = \"{base_name}-prod\";")
        
        # Customize settings
        if config_type == "runner":
            dev_block = dev_block.replace('PRODUCT_BUNDLE_IDENTIFIER = com.example.nms;', 'PRODUCT_BUNDLE_IDENTIFIER = com.maibathai.invoice.dev;')
            dev_block = dev_block.replace('INFOPLIST_FILE = Runner/Info.plist;', 'INFOPLIST_FILE = Runner/Info-dev.plist;')
            
            prod_block = prod_block.replace('PRODUCT_BUNDLE_IDENTIFIER = com.example.nms;', 'PRODUCT_BUNDLE_IDENTIFIER = com.maibathai.invoice;')
            prod_block = prod_block.replace('INFOPLIST_FILE = Runner/Info.plist;', 'INFOPLIST_FILE = Runner/Info-prod.plist;')
            
        elif config_type == "tests":
            dev_block = dev_block.replace('PRODUCT_BUNDLE_IDENTIFIER = com.example.nms.RunnerTests;', 'PRODUCT_BUNDLE_IDENTIFIER = com.maibathai.invoice.dev.RunnerTests;')
            prod_block = prod_block.replace('PRODUCT_BUNDLE_IDENTIFIER = com.example.nms.RunnerTests;', 'PRODUCT_BUNDLE_IDENTIFIER = com.maibathai.invoice.RunnerTests;')
            
        new_configs.append(dev_block)
        new_configs.append(prod_block)
        
        # Remove the original config from content
        content = content.replace(full_block, "")
    else:
        print(f"Warning: Could not find configuration block for {uuid}")

# Inject all new configurations into the XCBuildConfiguration section
configs_block = "\n".join(new_configs)
content = content.replace("/* Begin XCBuildConfiguration section */", f"/* Begin XCBuildConfiguration section */\n{configs_block}")

# 7. Rewrite XCConfigurationList section to map to the new configs
old_project_list = """\t\t97C146E91CF9000F007C117D /* Build configuration list for PBXProject "Runner" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t97C147031CF9000F007C117D /* Debug */,
\t\t\t\t97C147041CF9000F007C117D /* Release */,
\t\t\t\t249021D3217E4FDB00AE95B9 /* Profile */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};"""

new_project_list = """\t\t97C146E91CF9000F007C117D /* Build configuration list for PBXProject "Runner" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t97C147031CF9000F007D117D /* Debug-dev */,
\t\t\t\t97C147031CF9000F007E117D /* Debug-prod */,
\t\t\t\t97C147041CF9000F007D117D /* Release-dev */,
\t\t\t\t97C147041CF9000F007E117D /* Release-prod */,
\t\t\t\t249021D3217E4FDB00AD95B9 /* Profile-dev */,
\t\t\t\t249021D3217E4FDB00AC95B9 /* Profile-prod */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = "Release-prod";
\t\t};"""

content = content.replace(old_project_list, new_project_list)

old_runner_list = """\t\t97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t97C147061CF9000F007C117D /* Debug */,
\t\t\t\t97C147071CF9000F007C117D /* Release */,
\t\t\t\t249021D4217E4FDB00AE95B9 /* Profile */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};"""

new_runner_list = """\t\t97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t97C147061CF9000F007D117D /* Debug-dev */,
\t\t\t\t97C147061CF9000F007E117D /* Debug-prod */,
\t\t\t\t97C147071CF9000F007D117D /* Release-dev */,
\t\t\t\t97C147071CF9000F007E117D /* Release-prod */,
\t\t\t\t249021D4217E4FDB00AD95B9 /* Profile-dev */,
\t\t\t\t249021D4217E4FDB00AC95B9 /* Profile-prod */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = "Release-prod";
\t\t};"""

content = content.replace(old_runner_list, new_runner_list)

old_tests_list = """\t\t331C8087294A63A400263BE5 /* Build configuration list for PBXNativeTarget "RunnerTests" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t331C8088294A63A400263BE5 /* Debug */,
\t\t\t\t331C8089294A63A400263BE5 /* Release */,
\t\t\t\t331C808A294A63A400263BE5 /* Profile */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};"""

new_tests_list = """\t\t331C8087294A63A400263BE5 /* Build configuration list for PBXNativeTarget "RunnerTests" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t331C8088294A63A400273BE5 /* Debug-dev */,
\t\t\t\t331C8088294A63A400283BE5 /* Debug-prod */,
\t\t\t\t331C8089294A63A400273BE5 /* Release-dev */,
\t\t\t\t331C8089294A63A400283BE5 /* Release-prod */,
\t\t\t\t331C808A294A63A400273BE5 /* Profile-dev */,
\t\t\t\t331C808A294A63A400283BE5 /* Profile-prod */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = "Release-prod";
\t\t};"""

content = content.replace(old_tests_list, new_tests_list)

# Write modified file back
with open(project_path, "w") as f:
    f.write(content)

print("Successfully configured Xcode project configurations for dev/prod environments (Deployment Target 15.0)!")
