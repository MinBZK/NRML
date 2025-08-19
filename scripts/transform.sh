#!/bin/bash

# Modern XSLT 3.0 Transformation Script
# Uses Saxon-JS (xslt3) for fast, declarative NRML transformations
#
# Gebruik: ./transform-xslt.sh [stylesheet.xsl] [input.json] [output.txt]

set -euo pipefail

# Configuratie
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default waarden
XSLT_FILE="${1:-$PROJECT_ROOT/transformations/gegevensspraak.xsl}"
INPUT_FILE="${2:-$PROJECT_ROOT/toka.nrml.json}"
OUTPUT_FILE="${3:-$PROJECT_ROOT/objectmodel_xslt_output.txt}"
LANGUAGE="${4:-nl}"

function print_usage() {
    cat << EOF
🚀 NRML XSLT 3.0 Transformatie (Saxon-JS)

GEBRUIK:
    $0 [stylesheet.xsl] [input.json] [output.txt] [language]

ARGUMENTEN:
    stylesheet.xsl  XSLT transformatie bestand (default: ../transformations/gegevensspraak.xsl)
    input.json      NRML JSON bestand (default: ../toka.nrml.json)
    output.txt      Output bestand (default: ../objectmodel_xslt_output.txt)
    language        Taal code voor meertalige ondersteuning (default: nl)

VOORBEELDEN:
    $0                                              # Gebruik alle defaults (nl)
    $0 my-transform.xsl                             # Custom XSLT, default input/output/language
    $0 my-transform.xsl model.json                  # Custom XSLT en input
    $0 my-transform.xsl model.json output.txt       # Custom XSLT, input en output
    $0 my-transform.xsl model.json output.txt en    # Volledige custom met Engels

FEATURES:
    ✅ XSLT 3.0 declaratieve templates
    ✅ JSON native support (json-to-xml)
    ✅ Pattern matching op XML structuur
    ✅ Template inheritance
    ✅ Fast Saxon-JS engine
    ✅ Geen Java dependencies
    ✅ Meertalige ondersteuning (nl, en, etc)
    ✅ UUID-based v2 formaat support
    ✅ Backward compatible met v1 formaat

EOF
}

function validate_dependencies() {
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js niet gevonden. Installeer Node.js eerst."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "$SCRIPT_DIR/package.json" ]]; then
        echo "❌ NPM dependencies niet gevonden."
        echo "💡 Run eerst: cd scripts && npm install"
        exit 1
    fi
    
    echo "✅ Dependencies gevalideerd"
}

function validate_files() {
    if [[ ! -f "$XSLT_FILE" ]]; then
        echo "❌ XSLT transformatie niet gevonden: $XSLT_FILE"
        exit 1
    fi
    
    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "❌ Input bestand niet gevonden: $INPUT_FILE"
        exit 1
    fi
    
    # Valideer JSON syntax
    if command -v python3 &> /dev/null; then
        if ! python3 -m json.tool "$INPUT_FILE" > /dev/null 2>&1; then
            echo "❌ Ongeldige JSON syntax in: $INPUT_FILE"
            exit 1
        fi
    fi
    
    echo "🔄 XSLT transformatie: $XSLT_FILE"
    echo "📄 Input bestand: $INPUT_FILE"
    echo "📝 Output bestand: $OUTPUT_FILE"
    echo "🌍 Taal: $LANGUAGE"
}

function update_xslt_path() {
    # Update het JSON path in de XSLT voor correcte file locatie
    local relative_path
    # macOS compatible relative path calculation
    relative_path=$(python3 -c "import os; print(os.path.relpath('$INPUT_FILE', '$SCRIPT_DIR'))")
    
    # Temporary XSLT met correct path
    local temp_xslt="$SCRIPT_DIR/temp_gegevensspraak.xsl"
    # Update both old and new XSLT template formats
    sed -e "s|unparsed-text('../toka.nrml.json')|unparsed-text('$relative_path')|g" \
        -e "s|unparsed-text(\$input-file)|unparsed-text('$relative_path')|g" \
        "$XSLT_FILE" > "$temp_xslt"
    echo "$temp_xslt"
}

function run_xslt_transformation() {
    echo "⚡ XSLT 3.0 transformatie wordt uitgevoerd..."
    
    local start_time
    start_time=$(date +%s)
    
    # Update XSLT pad
    local temp_xslt
    temp_xslt=$(update_xslt_path)
    
    # Maak output directory aan indien nodig
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    
    # Voer XSLT transformatie uit met Saxon-JS
    cd "$SCRIPT_DIR"
    if npx xslt3 -it:main -xsl:"$(basename "$temp_xslt")" -o:"$OUTPUT_FILE" language="$LANGUAGE" input-file="$(python3 -c "import os; print(os.path.relpath('$INPUT_FILE', '$SCRIPT_DIR'))")" 2>/dev/null; then
        # Cleanup
        rm -f "$temp_xslt"
        
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [[ -f "$OUTPUT_FILE" ]]; then
            local output_size
            output_size=$(wc -c < "$OUTPUT_FILE")
            echo "✅ XSLT transformatie voltooid in ${duration}s"
            echo "📊 Output grootte: ${output_size} bytes"
            echo "🎯 Gegenereerd: $OUTPUT_FILE"
            
            # Toon eerste paar regels als preview
            echo ""
            echo "👀 Preview (eerste 10 regels):"
            head -10 "$OUTPUT_FILE"
            
            if [[ $(wc -l < "$OUTPUT_FILE") -gt 10 ]]; then
                echo "   ... (meer regels in $OUTPUT_FILE)"
            fi
        else
            echo "❌ XSLT transformatie gefaald - geen output gegenereerd"
            exit 1
        fi
    else
        # Cleanup on error
        rm -f "$temp_xslt"
        echo "❌ XSLT transformatie gefaald"
        exit 1
    fi
}

# Main execution
function main() {
    echo "🚀 NRML XSLT 3.0 Transformatie (Saxon-JS)"
    echo "========================================"
    
    # Parse argumenten
    case "${1:-}" in
        -h|--help)
            print_usage
            exit 0
            ;;
    esac
    
    # Validaties
    validate_dependencies
    validate_files
    
    echo ""
    
    # XSLT transformatie uitvoeren
    run_xslt_transformation
    
    echo ""
    echo "🎉 Declaratieve XSLT transformatie succesvol afgerond!"
    echo "💡 Saxon-JS verwerkte JSON → XML → Nederlandse gegevensspraak met template matching"
}

# Error handling
trap 'echo "❌ Fout opgetreden tijdens XSLT transformatie"' ERR

# Run main function
main "$@"