# =====================================================
# INDICATE SPE: Run Achilles Analysis
# =====================================================
# Purpose: Generate descriptive statistics for OMOP CDM
# Populates: results.achilles_* tables
# Runtime: ~2-5 minutes for 100 patients
# =====================================================

library(Achilles)
library(DatabaseConnector)

cat("=====================================================\n")
cat("INDICATE SPE: Achilles Analysis\n")
cat("=====================================================\n\n")

# =====================================================
# Configuration
# =====================================================
cat("Step 1: Configuring database connection...\n")

# Connection details
connectionDetails <- createConnectionDetails(
  dbms = "postgresql",
  server = "indicate-postgres-omop/omop_cdm",  # Docker network connection
  port = 5432,
  user = "postgres",
  password = "postgres"
)

# CDM configuration
cdmDatabaseSchema <- "cdm"
resultsDatabaseSchema <- "results"
vocabDatabaseSchema <- "vocab"
sourceName <- "INDICATE OMOP CDM"

cat("   ✓ Connection configured\n")
cat("   - Server: indicate-postgres-omop\n")
cat("   - Database: omop_cdm\n")
cat("   - CDM Schema: cdm\n")
cat("   - Results Schema: results\n")
cat("   - Vocab Schema: vocab\n\n")

# =====================================================
# Run Achilles Analysis
# =====================================================
cat("Step 2: Running Achilles analysis...\n")
cat("   (This may take 2-5 minutes for 100 patients)\n\n")

tryCatch({
  achilles(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    sourceName = sourceName,
    cdmVersion = "5.4",
    
    # Analysis options
    createTable = TRUE,              # Create achilles tables if needed
    smallCellCount = 0,              # Don't suppress small counts (demo data)
    
    # Performance options
    numThreads = 2,                  # Parallel threads
    outputFolder = "/tmp/achilles",  # Temporary output folder
    
    # Logging
    verboseMode = TRUE
  )
  
  cat("\n✓ Achilles analysis completed successfully!\n\n")
  
}, error = function(e) {
  cat("\n❌ Error running Achilles:\n")
  cat(paste("   ", e$message, "\n"))
  quit(status = 1)
})

# =====================================================
# Verify Results
# =====================================================
cat("Step 3: Verifying results...\n")

connection <- connect(connectionDetails)

# Check achilles_results
resultsCount <- querySql(connection, 
  "SELECT COUNT(*) as count FROM results.achilles_results")
cat(paste("   ✓ achilles_results:", resultsCount$COUNT, "rows\n"))

# Check achilles_results_dist
distCount <- querySql(connection, 
  "SELECT COUNT(*) as count FROM results.achilles_results_dist")
cat(paste("   ✓ achilles_results_dist:", distCount$COUNT, "rows\n"))

# Check achilles_analysis
analysisCount <- querySql(connection, 
  "SELECT COUNT(*) as count FROM results.achilles_analysis")
cat(paste("   ✓ achilles_analysis:", analysisCount$COUNT, "analyses\n"))

# Get key statistics
cat("\nKey Statistics:\n")

personCount <- querySql(connection,
  "SELECT stratum_1, count_value 
   FROM results.achilles_results 
   WHERE analysis_id = 1")
if (nrow(personCount) > 0) {
  cat(paste("   - Total Persons:", personCount$COUNT_VALUE[1], "\n"))
}

genderDist <- querySql(connection,
  "SELECT stratum_1, count_value 
   FROM results.achilles_results 
   WHERE analysis_id = 2")
if (nrow(genderDist) > 0) {
  cat("   - Gender Distribution:\n")
  for (i in 1:nrow(genderDist)) {
    gender <- ifelse(genderDist$STRATUM_1[i] == "8507", "Male", "Female")
    cat(paste("     -", gender, ":", genderDist$COUNT_VALUE[i], "\n"))
  }
}

disconnect(connection)

cat("\n=====================================================\n")
cat("✓ Achilles Setup Complete!\n")
cat("=====================================================\n\n")

cat("Next steps:\n")
cat("  1. Refresh Atlas UI: http://localhost:8081/atlas/\n")
cat("  2. Go to Data Sources > INDICATE OMOP CDM\n")
cat("  3. Click 'Report' tab to see statistics\n\n")