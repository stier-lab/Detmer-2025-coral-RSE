# Coral Restoration Strategy Evaluation Models

Code for coral restoration strategy evaluation models for *Acropora palmata* (Elkhorn Coral).

See full model description: https://docs.google.com/document/d/1BZKpY6Miuxl-hSjrSZDMMTi1NgYexdEllyUdFK8ZDHY/edit?tab=t.0

---

## 🚀 NEW: Interactive Web Application

A production-ready web application is now available for exploring the model interactively!

### Quick Start

```bash
cd coral-app
npm install
npm run dev
```

Open http://localhost:5173 to use the application.

### Features

- ✅ Interactive parameter controls
- ✅ Real-time population simulations
- ✅ Results dashboard with key metrics
- ✅ Modern, accessible interface
- ✅ Mobile-responsive design

**See [coral-app/README.md](coral-app/README.md) for details.**

---

## 📚 Documentation

### For Users
- **[QUICK_START.md](QUICK_START.md)** - Guide to all visualization materials
- **[coral-app/README.md](coral-app/README.md)** - Web application guide

### For Researchers
- **[docs/MODEL_ARCHITECTURE_SPECIFICATION.md](docs/MODEL_ARCHITECTURE_SPECIFICATION.md)** - Complete model specification (30k words)
- **[docs/README_VISUALIZATIONS.md](docs/README_VISUALIZATIONS.md)** - Visualization guide

### For Developers
- **[docs/FRONTEND_ARCHITECTURE.md](docs/FRONTEND_ARCHITECTURE.md)** - Technical architecture
- **[docs/FRONTEND_IMPLEMENTATION_SUMMARY.md](docs/FRONTEND_IMPLEMENTATION_SUMMARY.md)** - Implementation summary
- **[docs/VISUAL_DESIGN_SPECIFICATION.md](docs/VISUAL_DESIGN_SPECIFICATION.md)** - Design system guide

---

## 🗂️ Project Structure

```
Detmer-2025-coral-RSE/
├── coral-app/                 # 🆕 Interactive web application (React + TypeScript)
│   ├── src/
│   │   ├── lib/model/         # TypeScript model implementation
│   │   ├── components/        # UI components
│   │   └── ...
│   └── README.md
│
├── figures/                   # Interactive HTML visualizations
│   ├── modern_model_explorer.html      # State-of-the-art visualization
│   ├── interactive_model_guide.html    # 5-tab interactive guide
│   └── model_visual_summary.html       # Printable one-pager
│
├── docs/                      # Technical documentation
│   ├── MODEL_ARCHITECTURE_SPECIFICATION.md
│   ├── FRONTEND_ARCHITECTURE.md
│   ├── VISUAL_DESIGN_SPECIFICATION.md
│   ├── FRONTEND_IMPLEMENTATION_SUMMARY.md
│   └── README_VISUALIZATIONS.md
│
├── rse_funs.R                # Original R model functions
├── coral_demographic_funs.R  # Demographic calculation functions
├── model_description.Rmd     # Detailed model description
└── QUICK_START.md            # Quick start guide

```

---

## 🔬 Model Overview

This is a **stage-structured population dynamics model** for coral restoration, featuring:

- **5 size classes** (SC1-SC5) based on colony area
- **4 compartments**: External Reefs, Lab, Orchard, Restoration Reef
- **Demographic processes**: Survival, growth, shrinkage, fragmentation, reproduction
- **Management parameters**: Carrying capacity, collection efficiency, outplanting strategies

### Core Equation

```
N(t+1) = S · (T + F) · N(t) + R
```

Where:
- **S**: Survival matrix
- **T**: Transition matrix (growth/shrinkage/stasis)
- **F**: Fragmentation matrix (asexual reproduction)
- **R**: Recruitment vector

---

## 🎯 Choose Your Tool

### For Ecologists (No Programming)
👉 Open [`figures/modern_model_explorer.html`](figures/modern_model_explorer.html) in your browser

### For Interactive Exploration
👉 Run the web app: `cd coral-app && npm install && npm run dev`

### For Research/Analysis
👉 Use the R scripts: `rse_funs.R` and `coral_demographic_funs.R`

### For Development
👉 See [`docs/FRONTEND_ARCHITECTURE.md`](docs/FRONTEND_ARCHITECTURE.md)

---

## 📊 What's Available

| Resource | Type | Best For |
|----------|------|----------|
| **Web App** ([coral-app/](coral-app/)) | Interactive React app | Running simulations, exploring parameters |
| **Modern Explorer** ([figures/modern_model_explorer.html](figures/modern_model_explorer.html)) | HTML viz | Presentations, teaching, stakeholders |
| **Interactive Guide** ([figures/interactive_model_guide.html](figures/interactive_model_guide.html)) | HTML viz | Learning model structure |
| **Visual Summary** ([figures/model_visual_summary.html](figures/model_visual_summary.html)) | HTML viz | Quick reference, handouts |
| **R Scripts** (rse_funs.R) | R code | Research, custom analyses |

---

## 🚢 Deployment

### Web Application

The web app can be deployed to:
- **Netlify** (recommended) - Free tier available
- **Vercel** - Free tier available
- **GitHub Pages** - Free
- Any static hosting service

See [`coral-app/README.md`](coral-app/README.md) for deployment instructions.

---

## 🤝 Contributing

This is a research project from the Adrian Stier Lab. For questions or contributions:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## 📄 License

Research code for coral restoration strategy evaluation.

---

## 📧 Contact

**Adrian Stier Lab**
Department of Ecology, Evolution, and Marine Biology
University of California, Santa Barbara

For questions about the model or code, please open an issue on GitHub.

---

## 🌟 Quick Links

- 🚀 **[Start the Web App](coral-app/README.md)**
- 📖 **[Read the Documentation](QUICK_START.md)**
- 🎨 **[View Visualizations](figures/)**
- 🔬 **[Model Specification](docs/MODEL_ARCHITECTURE_SPECIFICATION.md)**

---

**Status**: Production-ready web application + comprehensive visualizations + complete documentation

**Built with**: React · TypeScript · R · D3.js · TailwindCSS

**For**: Coral reef restoration research and management
