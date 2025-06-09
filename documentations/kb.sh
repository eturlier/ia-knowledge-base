#!/bin/zsh

# Set script directory as working directory
SCRIPT_DIR=${0:a:h}
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source zsh profile to get environment variables and PATH
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc"
fi

cd "$SCRIPT_DIR" || exit 1

# Configuration
OUTPUT_FILE="$SCRIPT_DIR/kb.md"
HEADER_FILE="$SCRIPT_DIR/_header.md"
SPECS_DIR="specifications"
KNOWLEDGE_LIST="$SCRIPT_DIR/kb.txt"

# Initialize counters
count=0
additional_count=0

# Colors and formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Functions
log_info() {
    printf "%b→ %b%s%b\n" "$BLUE" "$NC" "$1" "$NC"
}

log_success() {
    printf "%b✓ %b%s%b\n" "$GREEN" "$NC" "$1" "$NC"
}

log_error() {
    printf "%b✗ %b%s%b\n" "$RED" "$NC" "$1" "$NC"
    exit 1
}

log_warning() {
    printf "%b! %b%s%b\n" "$YELLOW" "$NC" "$1" "$NC"
}

print_header() {
    printf "\n%b%s%b\n\n" "$BOLD" "$1" "$NC"
}

get_file_extension() {
    local filename=$1
    local ext="${filename##*.}"
    if [ "$ext" = "$filename" ]; then
        echo "txt"
    else
        echo "$ext"
    fi
}

process_file() {
    local pattern=$1
    
    cd "$PROJECT_ROOT"
    # Remove leading ./ if present to standardize paths
    pattern=${pattern#./}
    
    # Check if the pattern is a direct file path without wildcards
    if [[ ! "$pattern" =~ [*?] ]]; then
        # Direct file path handling
        if [ -f "$pattern" ]; then
            local relative_path="$pattern"
            local full_path="$PROJECT_ROOT/$relative_path"
            local ext=$(get_file_extension "$relative_path")
            log_info "Processing direct file: $relative_path"
            {
                printf "\n### %s\n\n" "$relative_path"
                printf "\`\`\`\`%s\n" "$ext"
                cat "$full_path"
                printf "\n\`\`\`\`\n"
            } >> "$OUTPUT_FILE"
            ((additional_count++))
        else
            log_warning "File not found: $pattern"
        fi
    else
        # Use zsh globbing for patterns with wildcards
        for file in $~pattern; do
            if [ -f "$file" ]; then
                local relative_path="${file#./}"
                local full_path="$PROJECT_ROOT/$relative_path"
                local ext=$(get_file_extension "$relative_path")
                log_info "Processing: $relative_path"
                {
                    printf "\n### %s\n\n" "$relative_path"
                    printf "\`\`\`\`%s\n" "$ext"
                    cat "$full_path"
                    printf "\n\`\`\`\`\n"
                } >> "$OUTPUT_FILE"
                ((additional_count++))
            fi
        done
    fi
    
    cd "$SCRIPT_DIR"
    return 0
}

process_rules() {
    local rules_dir=".cursor/rules"
    local windsurfrules_dir=".windsurf/rules"
    local temp_rules="/tmp/rules_content.md"
    local found_rules=false
    
    log_info "Checking for rules..."
    
    # Always start from PROJECT_ROOT
    cd "$PROJECT_ROOT" || {
        log_warning "Could not access project root, skipping rules processing"
        return 0
    }
    
    # Initialize temp_rules file if we can
    if ! echo "# Project rules" > "$temp_rules" 2>/dev/null; then
        log_warning "Could not create temporary rules file, skipping rules processing"
        return 0
    fi
    echo "" >> "$temp_rules"
    
    # Try to process rules from .cursor/rules if it exists
    if [ -d "$rules_dir" ]; then
        # Use find with error suppression
        if find "$rules_dir" -name "*.mdc" -type f 2>/dev/null | grep -q .; then
            log_info "Processing .mdc files from $rules_dir"
            while IFS= read -r rule_file; do
                if [ -f "$rule_file" ]; then
                    local filename=$(basename "$rule_file")
                    log_info "Processing rule: $filename"
                    
                    # Extract content after frontmatter
                    awk '
                        BEGIN { in_frontmatter=0; printed=0 }
                        /^---$/ {
                            if (in_frontmatter) {
                                in_frontmatter=0
                                next
                            } else {
                                in_frontmatter=1
                                next
                            }
                        }
                        !in_frontmatter && printed {
                            print
                        }
                        !in_frontmatter && !printed {
                            if (NF) {
                                print
                                printed=1
                            }
                        }
                    ' "$rule_file" >> "$temp_rules" 2>/dev/null && found_rules=true
                    echo "" >> "$temp_rules"
                fi
            done < <(find "$rules_dir" -name "*.mdc" -type f 2>/dev/null)
        else
            log_warning "No .mdc files found in $rules_dir"
        fi
    else
        log_warning "Rules directory '$rules_dir' not found"
    fi
    
    # Check for existing .windsurf/rules directory
    if [ -d "$windsurfrules_dir" ]; then
        # Use find with error suppression
        if find "$windsurfrules_dir" -name "*.mdc" -type f 2>/dev/null | grep -q .; then
            log_info "Processing .mdc files from $windsurfrules_dir"
            while IFS= read -r rule_file; do
                if [ -f "$rule_file" ]; then
                    local filename=$(basename "$rule_file")
                    log_info "Processing rule: $filename"
                    
                    # Extract content after frontmatter
                    awk '
                        BEGIN { in_frontmatter=0; printed=0 }
                        /^---$/ {
                            if (in_frontmatter) {
                                in_frontmatter=0
                                next
                            } else {
                                in_frontmatter=1
                                next
                            }
                        }
                        !in_frontmatter && printed {
                            print
                        }
                        !in_frontmatter && !printed {
                            if (NF) {
                                print
                                printed=1
                            }
                        }
                    ' "$rule_file" >> "$temp_rules" 2>/dev/null && found_rules=true
                    echo "" >> "$temp_rules"
                fi
            done < <(find "$windsurfrules_dir" -name "*.mdc" -type f 2>/dev/null)
        else
            log_warning "No .mdc files found in $windsurfrules_dir"
        fi
    else
        log_warning "Rules directory '$windsurfrules_dir' not found"
    fi
    
    # Cleanup
    rm -f "$temp_rules" 2>/dev/null
    
    # Always return to SCRIPT_DIR
    cd "$SCRIPT_DIR" 2>/dev/null || true
    
    # Always return success
    return 0
}

# Script header
print_header "1- Generating Documentation"

# Initial cleanup
log_info "Cleaning previous file..."
rm -f "$OUTPUT_FILE"

# Add YAML frontmatter with generation date
{
    echo "---"
    echo "date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
    echo ""
} > "$OUTPUT_FILE"

# Step 1: Copy header
log_info "Adding header file..."
if [ -f "$HEADER_FILE" ]; then
    cat "$HEADER_FILE" >> "$OUTPUT_FILE"
    printf "\n" >> "$OUTPUT_FILE"
    log_success "Header added successfully"
else
    log_warning "Header file not found ($HEADER_FILE)"
fi

# Step 2: Process specification files
print_header "2- Processing Specification Files"

# Create specifications directory if it doesn't exist
if [ ! -d "$SPECS_DIR" ]; then
    mkdir -p "$SPECS_DIR"
    log_info "Created specifications directory"
fi

# Process specification files using zsh globbing
cd "$SPECS_DIR"
for file in **/*.{md,mdx}(N.); do
    if [ -f "$file" ]; then
        log_info "Processing: $file"
        {
            cat "$file"
            printf "\n"
        } >> "$OUTPUT_FILE"
        ((count++))
    fi
done
cd "$SCRIPT_DIR"

# After processing specification files
print_header "3- Processing Rules"
if [ -d "$PROJECT_ROOT/$rules_dir" ]; then
    process_rules
else
    log_warning "Rules directory not found, skipping rules processing"
fi

# Step 3: Process additional files from kb.txt
if [ ! -f "$KNOWLEDGE_LIST" ]; then
    # Create kb.txt if it doesn't exist
    touch "$KNOWLEDGE_LIST"
    echo "# Add files to include in the documentation" > "$KNOWLEDGE_LIST"
    echo "# Example:" >> "$KNOWLEDGE_LIST"
    echo "# .cursor/rules/*.mdc" >> "$KNOWLEDGE_LIST"
    echo "# apps/backend/package.json" >> "$KNOWLEDGE_LIST"
    log_info "Created $KNOWLEDGE_LIST template file"
fi

if [ -f "$KNOWLEDGE_LIST" ]; then
    print_header "4- Processing Additional Files"
    printf "\n## Additional Files\n\n" >> "$OUTPUT_FILE"
    printf "> ⚠️ **IMPORTANT**: These files must be taken very seriously as they represent the latest up-to-date versions of our codebase. You MUST rely on these versions and their content imperatively.\n\n" >> "$OUTPUT_FILE"
    
    while IFS= read -r file; do
        # Skip empty lines and comments
        if [ ! -z "$file" ] && [[ ! "$file" =~ ^#.*$ ]]; then
            # Trim whitespace
            file=$(echo "$file" | xargs)
            process_file "$file"
            # Note: additional_count is now incremented inside process_file
        fi
    done < "$KNOWLEDGE_LIST"
fi

# Add project structure at the end
if [ -d "$PROJECT_ROOT" ]; then
    print_header "5- Project Structure"
    {
        printf "\n### Project Structure\n\n"
        printf "\`\`\`\`text\n"
        if command -v node >/dev/null 2>&1; then
            cd "$PROJECT_ROOT" && node ./documentations/flat-tree/flat-tree "coverage|dist|build|archives"
        else
            printf "Structure du projet non disponible: Node.js n'est pas installé ou n'est pas dans le PATH.\n"
            printf "Pour installer Node.js:\n"
            printf "• Alpine Linux: apk add nodejs npm\n"
            printf "• Debian/Ubuntu: apt-get install nodejs npm\n"
            printf "• Ou utilisez NVM: https://github.com/nvm-sh/nvm\n"
            find "$PROJECT_ROOT" -type d -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/coverage/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/archives/*" | sort | head -n 30 | sed "s#$PROJECT_ROOT/##g" | sed "s#^#/# "
        fi
        printf "\`\`\`\`\n"
    } >> "$OUTPUT_FILE"

    log_success "Project structure added successfully"
else
    log_warning "Project root directory not found, skipping project structure"
fi


# Summary
print_header "6- Summary"
log_success "$count specification files processed"
[ "$additional_count" -gt 0 ] && log_success "$additional_count additional files processed"
log_success "Documentation generated in: $OUTPUT_FILE"

# Add timestamp at the end of the file
printf "\n%s\n" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"

# Format the generated file with Prettier
if [ -f "$OUTPUT_FILE" ]; then
    if command -v pnpm &> /dev/null && ( [ -f "$PROJECT_ROOT/package.json" ] || [ -f "$SCRIPT_DIR/package.json" ] ); then
        log_info "Formatting generated file with Prettier..."
        if [ -f "$SCRIPT_DIR/package.json" ]; then
            cd "$SCRIPT_DIR" && pnpm prettier --write "$OUTPUT_FILE"
        else
            cd "$PROJECT_ROOT" && pnpm prettier --write "$OUTPUT_FILE"
        fi
        log_success "File formatted successfully"
    else
        log_warning "pnpm not found or no package file exists, skipping formatting"
    fi
else
    log_warning "Output file not found, skipping formatting"
fi
