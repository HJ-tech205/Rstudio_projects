
```markdown
# Automated ATS CV Screening & Database Ingestion Pipeline

A modular backend data engineering pipeline built in **R** that automates the ingestion, parsing, evaluation, and logging of applicant resumes. The system monitors a target directory for incoming PDF CVs, extracts key profile data using text mining and customized regular expressions, applies programmatic gatekeeping criteria, and securely syncs the structured results into a **PostgreSQL** relational database.

---

## 🚀 Key Features

* **Automated PDF Text Extraction:** Leverages binary extraction tools to ingest unstructured layout text directly from incoming resume files.
* **Smart Experience Extraction & Fallback:** Utilizes an advanced text parsing logic that looks for explicit experience phrase patterns. If absent, it automatically triggers a fallback algorithm that extracts historical date mentions to compute total professional experience span.
* **Flexible Multi-Skill Scanning:** Dynamically checks candidate profiles against a configurable array of technical target keywords (e.g., Full-Stack, Backend, and Data Science technologies).
* **Automated File Janitor (Archiving):** Automatically handles file clean-up by routing processed resumes out of the incoming inbox folder into a secure archive directory to prevent duplicate database entries.
* **Secure Database Ingestion:** Connects securely to a local PostgreSQL cluster using environment variables to mask sensitive database credentials (`.Renviron`).

---

## 📁 System Architecture

```text
ats-cv-pipeline/
├── data/
│   ├── incoming_cvs/       # The Inbox: Drop raw candidate PDF CVs here
│   └── processed_archive/  # The Vault: Successfully processed files are moved here
├── create_tables.R         # Setup Script: Instantiates PostgreSQL database schemas
├── pipeline.R              # Main Application: The data ingestion and filtering engine
├── .gitignore              # Security: Prevents environment keys and raw data from leaking
└── README.md               # Documentation
