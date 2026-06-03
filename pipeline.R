# ==============================================================================
# 1. LOAD COMPONENT LIBRARIES
# ==============================================================================
library(tidyverse) # For data manipulation & string processing
library(pdftools)  # For reading binary PDF files
library(DBI)       
library(RPostgres) 

# ==============================================================================
# 2. DEFINE ATS FILTERING CRITERIA
# ==============================================================================
TARGET_SKILLS <- c("java", "spring boot", "postgresql", "sql", "aws" , "next.js")
MIN_YEARS    <- 2

# ==============================================================================
# 3. LOCATE INCOMING CV FILES
# ==============================================================================
# Get paths for all PDF files in our incoming folder
pdf_files <- list.files(path = "data/incoming_cvs", pattern = "\\.pdf$", full.names = TRUE)

if (length(pdf_files) == 0) {
  stop("No PDF files found! Please drop some CV files into 'data/incoming_cvs/' first.")
}

# ==============================================================================
# 4. PROCESSING LOOP
# ==============================================================================
for (file_path in pdf_files) {
  
  # A. Extract text content from the PDF and convert to lowercase for easy matching
  raw_text <- pdftools::pdf_text(file_path) %>% 
    paste(collapse = " ") %>% 
    str_to_lower()
  # ==============================================================================
  # B. Extract Data Using Regular Expressions (Regex)
  # ==============================================================================
  
  # 1. Look for email patterns
  email_extracted <- str_extract(raw_text, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
  if (is.na(email_extracted)) email_extracted <- "unknown@email.com"
  
  # 2. Use the file name as the candidate's name
  file_clean_name <- basename(file_path) %>% 
    str_remove("\\.pdf$") %>% 
    str_replace_all("[_-]", " ") %>% 
    str_to_title()
  
  # 3. Smart Experience Extractor (Phrase Match + Date Fallback)
  exp_match <- str_extract(raw_text, "\\d+(?=\\s*(years|yrs)\\s*(of\\s*)?exp)")
  years_detected <- as.numeric(exp_match)
  
  # Fallback: If phrase extraction misses, calculate the span of years mentioned in the text
  if (is.na(years_detected) || years_detected == 0) {
    years_found <- str_extract_all(raw_text, "(19|20)\\d{2}")[[1]] %>% 
      unique() %>% 
      as.numeric()
    
    if (length(years_found) >= 2) {
      years_detected <- max(years_found) - min(years_found)
    } else {
      years_detected <- 0
    }
  }
  
  # 4. Multi-Skill Scanner Loop
  skills_found <- c()
  
  # Loop through your vector of keywords to extract all matches
  for (skill in TARGET_SKILLS) {
    if (str_detect(raw_text, skill)) {
      skills_found <- c(skills_found, skill)
    }
  }
  
  # Set Boolean flag if they have at least two valid skill parameter
  has_required_skills <- length(skills_found) >=2
  
  # Collapse matches into a single readable string for your database (e.g., "Sql, Postgresql")
  skills_matched_string <- paste(str_to_title(skills_found), collapse = ", ")
  
  # C. Apply ATS Filtering Gatekeeping Rules
  qualified <- TRUE
  fail_reason <- ""
  
  #handle the strings/messages for fail reason
  if (years_detected < MIN_YEARS) {
    qualified <- FALSE
    fail_reason <- paste0("Insufficient experience. Detected: ", years_detected, " years.")
  } else if (!has_required_skills) {
    qualified <- FALSE
    fail_reason <- paste0("Insufficient skills matched. Found ", length(skills_found), 
                          " skill(s) (", skills_matched_string, "), but required atleast 2.")
  }
  
  # ==============================================================================
  # 5. DATABASE INGESTION
  # ==============================================================================
  # CONNECT to PostgreSQL cluster
  con <- dbConnect(
    RPostgres::Postgres(), 
    dbname   = "ats_db", 
    host     = "localhost", 
    user     = "postgres", 
    password = Sys.getenv("DB_PASSWORD")
  )
  
  # ROUTE data based on qualification status
  if (qualified) {
    # Structure data match record frame for the Shortlist table
    df_pass <- data.frame(
      candidate_name   = file_clean_name, 
      email_address    = email_extracted, 
      years_experience = years_detected, 
      skills_matched   = skills_matched_string,
      stringsAsFactors = FALSE
    )
    dbWriteTable(con, "cv_shortlist", df_pass, append = TRUE, row.names = FALSE)
    message("✨ SUCCESS: ", file_clean_name, " -> [SHORTLISTED]")
    
  } else {
    # Structure tracking log entry for Discards table
    df_fail <- data.frame(
      candidate_name     = file_clean_name, 
      reason_for_discard = fail_reason,
      stringsAsFactors   = FALSE
    )
    dbWriteTable(con, "cv_discards", df_fail, append = TRUE, row.names = FALSE)
    message("DISCARDED: ", file_clean_name, " -> REASON: ", fail_reason)
  }
  
  # DISCONNECT channel cleanly
  dbDisconnect(con)
  # This takes the file from 'data/incoming_cvs/name.pdf' and moves it to 'data/processed_archive/name.pdf'
  new_archive_path <- str_replace(file_path, "incoming_cvs", "processed_archive")
  file.rename(from = file_path, to = new_archive_path)
}

print("Pipeline run execution finished completely!")