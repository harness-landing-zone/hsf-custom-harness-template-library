# 👋 START HERE - Documentation Guide

New to this repository? This guide will help you understand how everything works.

## 📚 Documentation Index

I've created comprehensive documentation to help you understand this repository. **Read in this order:**

### 1️⃣ **QUICK_REFERENCE.md** (Start Here!)
**Time: 5 minutes**

One-page cheat sheet with:
- TL;DR explanation
- Common commands
- File structure overview
- Quick troubleshooting

👉 **Start here if you:** Want to get up and running fast

---

### 2️⃣ **HOW_IT_WORKS.md** (Deep Dive)
**Time: 20 minutes**

Comprehensive explanation of:
- The core concept (convention over configuration)
- Three-layer architecture
- The merge system in detail
- Real examples traced through the code
- Why it's clever

👉 **Read this if you:** Want to understand the entire system

---

### 3️⃣ **ARCHITECTURE_DIAGRAM.md** (Visual Learner)
**Time: 10 minutes**

Visual diagrams showing:
- High-level flow
- File merge logic
- Project auto-discovery
- Data flow from user action to Harness
- The power of `merge()`

👉 **Read this if you:** Learn better with pictures

---

### 4️⃣ **EXAMPLES_AND_TROUBLESHOOTING.md** (Practical Guide)
**Time: 15 minutes**

Hands-on examples:
- Create your first org with projects
- Override templates
- Add org-specific resources
- Common issues and solutions
- Debugging techniques

👉 **Read this if you:** Want to actually use the system

---

### 5️⃣ **README.md** (Original Docs)
**Time: 15 minutes**

The original documentation from your peer:
- Prerequisites
- Deployment workflow
- YAML schema reference
- Configuration details

👉 **Read this if you:** Need specific YAML schema details

---

## 🎯 Quick Start Paths

### Path 1: "I just want to use this"
1. Read **QUICK_REFERENCE.md** (5 min)
2. Follow Example 1 in **EXAMPLES_AND_TROUBLESHOOTING.md** (10 min)
3. Refer back to **QUICK_REFERENCE.md** as needed

**Total time: 15 minutes**

---

### Path 2: "I need to understand how it works"
1. Read **QUICK_REFERENCE.md** (5 min)
2. Read **HOW_IT_WORKS.md** sections 1-4 (15 min)
3. Look at **ARCHITECTURE_DIAGRAM.md** (10 min)
4. Read **HOW_IT_WORKS.md** sections 5-7 (10 min)

**Total time: 40 minutes**

---

### Path 3: "I have a specific problem"
1. Check **QUICK_REFERENCE.md** → Troubleshooting Quick Fixes (2 min)
2. If not solved, go to **EXAMPLES_AND_TROUBLESHOOTING.md** → Troubleshooting section
3. Still stuck? Read relevant section in **HOW_IT_WORKS.md**

**Total time: 5-20 minutes**

---

### Path 4: "I'm a visual learner"
1. Start with **ARCHITECTURE_DIAGRAM.md** (10 min)
2. Read **HOW_IT_WORKS.md** → "Real Example: Let's Trace It" (5 min)
3. Try Example 1 from **EXAMPLES_AND_TROUBLESHOOTING.md** (10 min)

**Total time: 25 minutes**

---

## 💡 Key Concepts to Understand

Before diving in, understand these core ideas:

### 1. Convention Over Configuration
**Add folder → Get resource automatically**

No need to edit Terraform code. Just create folders and YAML files.

### 2. Three Layers
- **Layer 1:** Account setup (`harness-platform-setup/`)
- **Layer 2:** Org + auto-discovered projects (`harness-organization/`)
- **Layer 3:** Individual projects (`harness-project/`)

### 3. Template + Override Pattern
- Templates provide defaults
- Your configs override defaults
- Same filename = override
- Different filename = addition

### 4. The Merge Magic
```hcl
merge(template_files, your_files)  # Your files win!
```

This is how overrides work.

### 5. Auto-Discovery
```
platform-configs/organizations/MyOrg/projects/
├── Project1/config.yaml    ← Folder = Project
├── Project2/config.yaml    ← Folder = Project
└── Project3/config.yaml    ← Folder = Project

Run harness-organization/ → 3 projects created!
```

---

## 🚀 Your First Steps

### Step 1: Understand the Repo (5 min)
Read **QUICK_REFERENCE.md** → "TL;DR - How It Works"

### Step 2: Explore the Structure (5 min)
```bash
# Look at the directory structure
ls -la
ls platform-configs/organizations/

# Check out an example
cat platform-configs/organizations/Example\ Org\ One/config.yaml
ls platform-configs/organizations/Example\ Org\ One/projects/
```

### Step 3: Try a Deployment (20 min)
Follow Example 1 in **EXAMPLES_AND_TROUBLESHOOTING.md**

### Step 4: Understand What Happened (15 min)
Read **HOW_IT_WORKS.md** → "Real Example: Let's Trace It"

---

## 🎓 Learning Objectives

By the end of reading these docs, you should be able to:

✅ Explain how the three-layer architecture works  
✅ Create a new organization with projects  
✅ Override a template with custom configuration  
✅ Add org-specific or project-specific resources  
✅ Debug issues using Terraform console  
✅ Understand how the merge system works  
✅ Trace the data flow from YAML to Harness resource  

---

## 📖 Documentation Overview Table

| Document | Purpose | When to Read | Time |
|----------|---------|--------------|------|
| **QUICK_REFERENCE.md** | Cheat sheet | First, and often | 5 min |
| **HOW_IT_WORKS.md** | Complete explanation | When you want to understand | 20 min |
| **ARCHITECTURE_DIAGRAM.md** | Visual guide | When diagrams help | 10 min |
| **EXAMPLES_AND_TROUBLESHOOTING.md** | Practical guide | When doing actual work | 15 min |
| **README.md** | Original docs | For YAML schema reference | 15 min |
| **CONTRIBUTING.md** | Contribution guide | Before submitting changes | 5 min |

---

## 🔧 Common Questions

**Q: Do I need to edit Terraform code?**  
A: No! Just create folders and YAML files. Terraform auto-discovers them.

**Q: How do I add a new project?**  
A: Create folder under `platform-configs/organizations/<Org>/projects/<ProjectName>/` with `config.yaml`, then re-run org terraform.

**Q: How do I customize a default?**  
A: Copy the template file to your org folder with the same name. Your version wins.

**Q: What if I break something?**  
A: Always run `make plan` first. Terraform shows you what will change before applying.

**Q: Can I skip the Docker/Makefile?**  
A: Yes! Install tofu/terraform locally and run directly. See QUICK_REFERENCE.md → "Run without Docker"

**Q: Where should I put my credentials?**  
A: Set `HARNESS_PLATFORM_API_KEY` as environment variable. Don't commit it!

---

## 🆘 Getting Help

1. **Quick answer:** Check **QUICK_REFERENCE.md** → Troubleshooting Quick Fixes
2. **Specific problem:** Read **EXAMPLES_AND_TROUBLESHOOTING.md** → Troubleshooting section
3. **Conceptual question:** Read relevant section in **HOW_IT_WORKS.md**
4. **Still stuck:** Enable debug logging and inspect locals

```bash
# Debug mode
export TF_LOG=DEBUG
make plan 2>&1 | tee debug.log

# Inspect what Terraform sees
terraform console
> local.merged_sources["projects"]
```

---

## 🎯 Your Next Steps

**Right Now:**
1. [ ] Read **QUICK_REFERENCE.md** (5 min)
2. [ ] Skim **ARCHITECTURE_DIAGRAM.md** (5 min)
3. [ ] Choose your learning path above

**Today:**
1. [ ] Read **HOW_IT_WORKS.md** (20 min)
2. [ ] Try Example 1 from **EXAMPLES_AND_TROUBLESHOOTING.md** (20 min)

**This Week:**
1. [ ] Deploy to your test Harness account
2. [ ] Create a custom org with projects
3. [ ] Override a template with custom config

---

## 📊 Repository Health Check

Before using this repo, verify:

```bash
# 1. Docker is running (if using Make)
docker ps

# 2. Required files exist
ls harness-organization/terraform.tfvars.example
ls platform-configs/organizations/

# 3. YAML files are valid
find platform-configs -name "*.yaml" -exec \
  python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]))" {} \;

# 4. Terraform is available (if not using Docker)
tofu version || terraform version
```

---

## 🎉 Ready to Start!

Pick your path above and dive in. Remember:

- **Start small** - Create one org, one project
- **Always plan first** - `make plan` before `make apply`
- **Use examples** - The Example Org One is there for reference
- **Ask questions** - Check the docs, they're comprehensive!

**Your peer built something clever. These docs will help you master it!**

---

## 📝 Documentation Credits

These documentation files were created to help you understand the architecture and patterns in this repository:

- Original repo by your peer (excellent Terraform skills!)
- Documentation guides created to explain how it all works
- All docs are in the repository root for easy access

Happy learning! 🚀
