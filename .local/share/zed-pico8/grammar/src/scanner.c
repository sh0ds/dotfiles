// The body of a PICO-8 cart section: every line up to the next line that is
// only __name__ (letters and digits between double underscores), or the end.
#include "tree_sitter/parser.h"

enum TokenType { BODY };

void *tree_sitter_p8_external_scanner_create(void) { return NULL; }
void tree_sitter_p8_external_scanner_destroy(void *payload) {}
unsigned tree_sitter_p8_external_scanner_serialize(void *payload, char *buffer) { return 0; }
void tree_sitter_p8_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {}

static bool is_name(int32_t c) {
  return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9');
}

// At the start of a line: is it a section marker? Reads it (as lookahead).
static bool marker_line(TSLexer *lexer) {
  if (lexer->lookahead != '_') return false;
  lexer->advance(lexer, false);
  if (lexer->lookahead != '_') return false;
  lexer->advance(lexer, false);
  int n = 0;
  while (is_name(lexer->lookahead)) { lexer->advance(lexer, false); n++; }
  if (n == 0 || lexer->lookahead != '_') return false;
  lexer->advance(lexer, false);
  if (lexer->lookahead != '_') return false;
  lexer->advance(lexer, false);
  while (lexer->lookahead == ' ' || lexer->lookahead == '\t' || lexer->lookahead == '\r')
    lexer->advance(lexer, false);
  return lexer->lookahead == '\n' || lexer->eof(lexer);
}

bool tree_sitter_p8_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
  if (!valid_symbols[BODY]) return false;
  bool any = false;
  while (!lexer->eof(lexer)) {
    if (marker_line(lexer)) break;
    while (!lexer->eof(lexer) && lexer->lookahead != '\n') lexer->advance(lexer, false);
    if (!lexer->eof(lexer)) lexer->advance(lexer, false); // the newline
    lexer->mark_end(lexer);
    any = true;
  }
  if (!any) return false;
  lexer->result_symbol = BODY;
  return true;
}
