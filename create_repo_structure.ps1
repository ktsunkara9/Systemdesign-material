# ==========================================
# Engineering Knowledge Base Structure
# ==========================================

$folders = @(

# ---------------------------------------------------
# 00 - Index
# ---------------------------------------------------
"00-Index",

# ---------------------------------------------------
# 01 - Computer Science
# ---------------------------------------------------
"01-Computer-Science",
"01-Computer-Science/Operating-Systems",
"01-Computer-Science/Networking",
"01-Computer-Science/DBMS",
"01-Computer-Science/OOP",
"01-Computer-Science/Data-Structures",
"01-Computer-Science/Algorithms",

# ---------------------------------------------------
# 02 - System Design (SD60)
# ---------------------------------------------------
"02-System-Design",

"02-System-Design/01-Fundamentals",
"02-System-Design/02-Patterns",
"02-System-Design/03-Architectures",
"02-System-Design/04-System-Designs",
"02-System-Design/05-Revision",
"02-System-Design/06-Interview-Questions",

# ---------------------------------------------------
# 03 - Backend Engineering
# ---------------------------------------------------
"03-Backend-Engineering",
"03-Backend-Engineering/Java",
"03-Backend-Engineering/Spring",
"03-Backend-Engineering/REST",
"03-Backend-Engineering/GraphQL",

# ---------------------------------------------------
# 04 - Cloud
# ---------------------------------------------------
"04-Cloud",
"04-Cloud/AWS",
"04-Cloud/Azure",
"04-Cloud/GCP",
"04-Cloud/Kubernetes",
"04-Cloud/Docker",
"04-Cloud/Terraform",

# ---------------------------------------------------
# 05 - Databases
# ---------------------------------------------------
"05-Databases",
"05-Databases/SQL",
"05-Databases/NoSQL",

# ---------------------------------------------------
# 06 - AI & Machine Learning
# ---------------------------------------------------
"06-AI-and-Machine-Learning",
"06-AI-and-Machine-Learning/Foundations",
"06-AI-and-Machine-Learning/Generative-AI",
"06-AI-and-Machine-Learning/Bedrock",
"06-AI-and-Machine-Learning/SageMaker",
"06-AI-and-Machine-Learning/RAG",
"06-AI-and-Machine-Learning/Agents",
"06-AI-and-Machine-Learning/MCP",

# ---------------------------------------------------
# 07 - Domains
# ---------------------------------------------------
"07-Domains",

"07-Domains/Finance",
"07-Domains/Airlines",
"07-Domains/Publishing",
"07-Domains/Retail",
"07-Domains/Healthcare",

# ---------------------------------------------------
# 08 - Case Studies
# ---------------------------------------------------
"08-Case-Studies",
"08-Case-Studies/Delta",
"08-Case-Studies/LSEG",
"08-Case-Studies/Taylor-Francis",
"08-Case-Studies/Personal-Projects",

# ---------------------------------------------------
# 09 - Interview Preparation
# ---------------------------------------------------
"09-Interview-Preparation",
"09-Interview-Preparation/Behavioral",
"09-Interview-Preparation/Resume",
"09-Interview-Preparation/Leadership",

# ---------------------------------------------------
# 10 - Real Interview Questions
# ---------------------------------------------------
"10-Real-Interview-Questions",
"10-Real-Interview-Questions/Amazon",
"10-Real-Interview-Questions/Google",
"10-Real-Interview-Questions/Meta",
"10-Real-Interview-Questions/Microsoft",
"10-Real-Interview-Questions/Oracle",
"10-Real-Interview-Questions/Delta",
"10-Real-Interview-Questions/LSEG",
"10-Real-Interview-Questions/JPMC",
"10-Real-Interview-Questions/PayU",
"10-Real-Interview-Questions/Amadeus",

# ---------------------------------------------------
# Misc
# ---------------------------------------------------
"11-Projects",
"12-Cheat-Sheets",
"13-Templates",
"99-Resources"

)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
}

Write-Host ""
Write-Host "=========================================="
Write-Host " Engineering Knowledge Base Created"
Write-Host "=========================================="