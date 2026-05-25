import os

base_dir = "ios/Runner.xcodeproj/xcshareddata/xcschemes"
runner_path = os.path.join(base_dir, "Runner.xcscheme")
dev_path = os.path.join(base_dir, "dev.xcscheme")
prod_path = os.path.join(base_dir, "prod.xcscheme")

if not os.path.exists(runner_path):
    print("Error: Runner.xcscheme not found.")
    exit(1)

with open(runner_path, "r") as f:
    original = f.read()

# Create dev.xcscheme
dev_content = original.replace('buildConfiguration = "Debug"', 'buildConfiguration = "Debug-dev"')
dev_content = dev_content.replace('buildConfiguration = "Profile"', 'buildConfiguration = "Profile-dev"')
dev_content = dev_content.replace('buildConfiguration = "Release"', 'buildConfiguration = "Release-dev"')

with open(dev_path, "w") as f:
    f.write(dev_content)

# Create prod.xcscheme
prod_content = original.replace('buildConfiguration = "Debug"', 'buildConfiguration = "Debug-prod"')
prod_content = prod_content.replace('buildConfiguration = "Profile"', 'buildConfiguration = "Profile-prod"')
prod_content = prod_content.replace('buildConfiguration = "Release"', 'buildConfiguration = "Release-prod"')

with open(prod_path, "w") as f:
    f.write(prod_content)

# Delete Runner.xcscheme
os.remove(runner_path)

print("Created dev.xcscheme and prod.xcscheme, and removed original Runner.xcscheme.")
