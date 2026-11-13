// A PICO-8 cart (.p8): a header, then sections that each start with a
// __name__ line. Only __lua__ is code; Zed colours it with the Lua grammar
// (queries/injections.scm in the extension). The scanner (src/scanner.c)
// reads everything up to the next __name__ line as one block.
module.exports = grammar({
  name: 'p8',
  extras: () => [],
  externals: $ => [$._body],
  rules: {
    cart: $ => seq(
      optional(alias($._body, $.header)),
      repeat(choice($.lua_section, $.data_section)),
    ),
    lua_section: $ => seq($.lua_marker, optional(alias($._body, $.lua_code))),
    data_section: $ => seq($.section_marker, optional(alias($._body, $.data))),
    lua_marker: () => token(prec(2, /__lua__[ \t]*\r?\n?/)),
    section_marker: () => token(prec(1, /__[a-z0-9]+__[ \t]*\r?\n?/)),
  },
});
