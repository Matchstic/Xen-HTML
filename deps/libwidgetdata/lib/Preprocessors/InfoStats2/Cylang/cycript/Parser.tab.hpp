// A Bison parser, made by GNU Bison 3.0.4.

// Skeleton interface for Bison LALR(1) parsers in C++

// Copyright (C) 2002-2015 Free Software Foundation, Inc.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// As a special exception, you may create a larger work that contains
// part or all of the Bison parser skeleton and distribute that work
// under terms of your choice, so long as that work isn't itself a
// parser generator using the skeleton or a modified version thereof
// as a parser skeleton.  Alternatively, if you modify or redistribute
// the parser skeleton itself, you may (at your option) remove this
// special exception, which will cause the skeleton and the resulting
// Bison output files to be licensed under the GNU General Public
// License without this special exception.

// This special exception was added by the Free Software Foundation in
// version 2.2 of Bison.

/**
 ** \file Parser.hpp
 ** Define the cy::parser class.
 */

// C++ LALR(1) parser skeleton written by Akim Demaille.

#ifndef YY_CY_PARSER_HPP_INCLUDED
# define YY_CY_PARSER_HPP_INCLUDED
// //                    "%code requires" blocks.
#line 26 "Parser.ypp" // lalr1.cc:392

#include "Driver.hpp"
#include "Parser.tab.hpp"
#include "Stack.hpp"
#include "Syntax.hpp"
#define CYNew new(driver.pool_)

#include "ObjectiveC/Syntax.hpp"


#include "Highlight.hpp"

#line 57 "Parser.hpp" // lalr1.cc:392


# include <cstdlib> // std::abort
# include <iostream>
# include <stdexcept>
# include <string>
# include <vector>
# include "stack.hh"



#ifndef YY_ATTRIBUTE
# if (defined __GNUC__                                               \
      && (2 < __GNUC__ || (__GNUC__ == 2 && 96 <= __GNUC_MINOR__)))  \
     || defined __SUNPRO_C && 0x5110 <= __SUNPRO_C
#  define YY_ATTRIBUTE(Spec) __attribute__(Spec)
# else
#  define YY_ATTRIBUTE(Spec) /* empty */
# endif
#endif

#ifndef YY_ATTRIBUTE_PURE
# define YY_ATTRIBUTE_PURE   YY_ATTRIBUTE ((__pure__))
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# define YY_ATTRIBUTE_UNUSED YY_ATTRIBUTE ((__unused__))
#endif

#if !defined _Noreturn \
     && (!defined __STDC_VERSION__ || __STDC_VERSION__ < 201112)
# if defined _MSC_VER && 1200 <= _MSC_VER
#  define _Noreturn __declspec (noreturn)
# else
#  define _Noreturn YY_ATTRIBUTE ((__noreturn__))
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(E) ((void) (E))
#else
# define YYUSE(E) /* empty */
#endif

#if defined __GNUC__ && 407 <= __GNUC__ * 100 + __GNUC_MINOR__
/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN \
    _Pragma ("GCC diagnostic push") \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")\
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# define YY_IGNORE_MAYBE_UNINITIALIZED_END \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif


namespace cy {
#line 129 "Parser.hpp" // lalr1.cc:392





  /// A Bison parser.
  class parser
  {
  public:
#ifndef YYSTYPE
    /// Symbol semantic values.
    union semantic_type
    {
    #line 39 "Parser.ypp" // lalr1.cc:392
 bool bool_; 
#line 41 "Parser.ypp" // lalr1.cc:392
 CYMember *access_; 
#line 42 "Parser.ypp" // lalr1.cc:392
 CYArgument *argument_; 
#line 43 "Parser.ypp" // lalr1.cc:392
 CYAssignment *assignment_; 
#line 44 "Parser.ypp" // lalr1.cc:392
 CYBinding *binding_; 
#line 45 "Parser.ypp" // lalr1.cc:392
 CYBindings *bindings_; 
#line 46 "Parser.ypp" // lalr1.cc:392
 CYBoolean *boolean_; 
#line 47 "Parser.ypp" // lalr1.cc:392
 CYBraced *braced_; 
#line 48 "Parser.ypp" // lalr1.cc:392
 CYClause *clause_; 
#line 49 "Parser.ypp" // lalr1.cc:392
 cy::Syntax::Catch *catch_; 
#line 50 "Parser.ypp" // lalr1.cc:392
 CYClassTail *classTail_; 
#line 51 "Parser.ypp" // lalr1.cc:392
 CYComprehension *comprehension_; 
#line 52 "Parser.ypp" // lalr1.cc:392
 CYElement *element_; 
#line 53 "Parser.ypp" // lalr1.cc:392
 CYEnumConstant *constant_; 
#line 54 "Parser.ypp" // lalr1.cc:392
 CYExpression *expression_; 
#line 55 "Parser.ypp" // lalr1.cc:392
 CYFalse *false_; 
#line 56 "Parser.ypp" // lalr1.cc:392
 CYVariable *variable_; 
#line 57 "Parser.ypp" // lalr1.cc:392
 CYFinally *finally_; 
#line 58 "Parser.ypp" // lalr1.cc:392
 CYForInitializer *for_; 
#line 59 "Parser.ypp" // lalr1.cc:392
 CYForInInitializer *forin_; 
#line 60 "Parser.ypp" // lalr1.cc:392
 CYFunctionParameter *functionParameter_; 
#line 61 "Parser.ypp" // lalr1.cc:392
 CYIdentifier *identifier_; 
#line 62 "Parser.ypp" // lalr1.cc:392
 CYImportSpecifier *import_; 
#line 63 "Parser.ypp" // lalr1.cc:392
 CYInfix *infix_; 
#line 64 "Parser.ypp" // lalr1.cc:392
 CYLiteral *literal_; 
#line 65 "Parser.ypp" // lalr1.cc:392
 CYMethod *method_; 
#line 66 "Parser.ypp" // lalr1.cc:392
 CYModule *module_; 
#line 67 "Parser.ypp" // lalr1.cc:392
 CYNull *null_; 
#line 68 "Parser.ypp" // lalr1.cc:392
 CYNumber *number_; 
#line 69 "Parser.ypp" // lalr1.cc:392
 CYParenthetical *parenthetical_; 
#line 70 "Parser.ypp" // lalr1.cc:392
 CYProperty *property_; 
#line 71 "Parser.ypp" // lalr1.cc:392
 CYPropertyName *propertyName_; 
#line 72 "Parser.ypp" // lalr1.cc:392
 CYTypeSigning signing_; 
#line 73 "Parser.ypp" // lalr1.cc:392
 CYSpan *span_; 
#line 74 "Parser.ypp" // lalr1.cc:392
 CYStatement *statement_; 
#line 75 "Parser.ypp" // lalr1.cc:392
 CYString *string_; 
#line 76 "Parser.ypp" // lalr1.cc:392
 CYTarget *target_; 
#line 77 "Parser.ypp" // lalr1.cc:392
 CYThis *this_; 
#line 78 "Parser.ypp" // lalr1.cc:392
 CYTrue *true_; 
#line 79 "Parser.ypp" // lalr1.cc:392
 CYWord *word_; 
#line 81 "Parser.ypp" // lalr1.cc:392
 CYTypeIntegral *integral_; 
#line 82 "Parser.ypp" // lalr1.cc:392
 CYTypeStructField *structField_; 
#line 83 "Parser.ypp" // lalr1.cc:392
 CYTypeModifier *modifier_; 
#line 84 "Parser.ypp" // lalr1.cc:392
 CYTypeSpecifier *specifier_; 
#line 85 "Parser.ypp" // lalr1.cc:392
 CYTypedFormal *typedFormal_; 
#line 86 "Parser.ypp" // lalr1.cc:392
 CYTypedLocation *typedLocation_; 
#line 87 "Parser.ypp" // lalr1.cc:392
 CYTypedName *typedName_; 
#line 88 "Parser.ypp" // lalr1.cc:392
 CYTypedParameter *typedParameter_; 
#line 89 "Parser.ypp" // lalr1.cc:392
 CYType *typedThing_; 
#line 91 "Parser.ypp" // lalr1.cc:392
 CYObjCKeyValue *keyValue_; 
#line 92 "Parser.ypp" // lalr1.cc:392
 CYImplementationField *implementationField_; 
#line 93 "Parser.ypp" // lalr1.cc:392
 CYMessage *message_; 
#line 94 "Parser.ypp" // lalr1.cc:392
 CYMessageParameter *messageParameter_; 
#line 95 "Parser.ypp" // lalr1.cc:392
 CYProtocol *protocol_; 
#line 96 "Parser.ypp" // lalr1.cc:392
 CYSelectorPart *selector_; 

#line 254 "Parser.hpp" // lalr1.cc:392
    };
#else
    typedef YYSTYPE semantic_type;
#endif
    /// Symbol locations.
    typedef  CYLocation  location_type;

    /// Syntax errors thrown from user actions.
    struct syntax_error : std::runtime_error
    {
      syntax_error (const location_type& l, const std::string& m);
      location_type location;
    };

    /// Tokens.
    struct token
    {
      enum yytokentype
      {
        Ampersand = 258,
        AmpersandAmpersand = 259,
        AmpersandEqual = 260,
        Carrot = 261,
        CarrotEqual = 262,
        Equal = 263,
        EqualEqual = 264,
        EqualEqualEqual = 265,
        EqualRight = 266,
        Exclamation = 267,
        ExclamationEqual = 268,
        ExclamationEqualEqual = 269,
        Hyphen = 270,
        HyphenEqual = 271,
        HyphenHyphen = 272,
        HyphenRight = 273,
        Left = 274,
        LeftEqual = 275,
        LeftLeft = 276,
        LeftLeftEqual = 277,
        Percent = 278,
        PercentEqual = 279,
        Period = 280,
        PeriodPeriodPeriod = 281,
        Pipe = 282,
        PipeEqual = 283,
        PipePipe = 284,
        Plus = 285,
        PlusEqual = 286,
        PlusPlus = 287,
        QuestionPeriod = 288,
        Right = 289,
        RightEqual = 290,
        RightRight = 291,
        RightRightEqual = 292,
        RightRightRight = 293,
        RightRightRightEqual = 294,
        Slash = 295,
        SlashEqual = 296,
        Star = 297,
        StarEqual = 298,
        Tilde = 299,
        Colon = 300,
        ColonColon = 301,
        Comma = 302,
        Question = 303,
        SemiColon = 304,
        Pound = 305,
        NewLine = 306,
        __ = 307,
        Comment = 308,
        OpenParen = 309,
        CloseParen = 310,
        OpenBrace = 311,
        OpenBrace_ = 312,
        OpenBrace_let = 313,
        CloseBrace = 314,
        OpenBracket = 315,
        OpenBracket_let = 316,
        CloseBracket = 317,
        At_error_ = 318,
        At_class_ = 319,
        _typedef_ = 320,
        _unsigned_ = 321,
        _signed_ = 322,
        _struct_ = 323,
        _extern_ = 324,
        At_encode_ = 325,
        At_implementation_ = 326,
        At_import_ = 327,
        At_end_ = 328,
        At_selector_ = 329,
        At_null_ = 330,
        At_YES_ = 331,
        At_NO_ = 332,
        At_true_ = 333,
        At_false_ = 334,
        _YES_ = 335,
        _NO_ = 336,
        _false_ = 337,
        _null_ = 338,
        _true_ = 339,
        _as_ = 340,
        _break_ = 341,
        _case_ = 342,
        _catch_ = 343,
        _class_ = 344,
        _class__ = 345,
        _const_ = 346,
        _continue_ = 347,
        _debugger_ = 348,
        _default_ = 349,
        _delete_ = 350,
        _do_ = 351,
        _else_ = 352,
        _enum_ = 353,
        _export_ = 354,
        _extends_ = 355,
        _finally_ = 356,
        _for_ = 357,
        _function_ = 358,
        _function__ = 359,
        _if_ = 360,
        _import_ = 361,
        _in_ = 362,
        _in__ = 363,
        _Infinity_ = 364,
        _instanceof_ = 365,
        _new_ = 366,
        _return_ = 367,
        _super_ = 368,
        _switch_ = 369,
        _target_ = 370,
        _this_ = 371,
        _throw_ = 372,
        _try_ = 373,
        _typeof_ = 374,
        _var_ = 375,
        _void_ = 376,
        _while_ = 377,
        _with_ = 378,
        _abstract_ = 379,
        _await_ = 380,
        _boolean_ = 381,
        _byte_ = 382,
        _char_ = 383,
        _constructor_ = 384,
        _double_ = 385,
        _eval_ = 386,
        _final_ = 387,
        _float_ = 388,
        _from_ = 389,
        _get_ = 390,
        _goto_ = 391,
        _implements_ = 392,
        _int_ = 393,
        ___int128_ = 394,
        _interface_ = 395,
        _let_ = 396,
        _let__ = 397,
        _long_ = 398,
        _native_ = 399,
        _package_ = 400,
        _private_ = 401,
        _protected_ = 402,
        ___proto___ = 403,
        _prototype_ = 404,
        _public_ = 405,
        _set_ = 406,
        _short_ = 407,
        _static_ = 408,
        _synchronized_ = 409,
        _throws_ = 410,
        _transient_ = 411,
        _typeid_ = 412,
        _volatile_ = 413,
        _yield_ = 414,
        _yield__ = 415,
        _undefined_ = 416,
        _bool_ = 417,
        _BOOL_ = 418,
        _id_ = 419,
        _nil_ = 420,
        _NULL_ = 421,
        _SEL_ = 422,
        _each_ = 423,
        _of_ = 424,
        _of__ = 425,
        AutoComplete = 426,
        YieldStar = 427,
        Identifier_ = 428,
        NumericLiteral = 429,
        StringLiteral = 430,
        RegularExpressionLiteral_ = 431,
        NoSubstitutionTemplate = 432,
        TemplateHead = 433,
        TemplateMiddle = 434,
        TemplateTail = 435,
        MarkModule = 436,
        MarkScript = 437,
        MarkExpression = 438
      };
    };

    /// (External) token type, as returned by yylex.
    typedef token::yytokentype token_type;

    /// Symbol type: an internal symbol number.
    typedef int symbol_number_type;

    /// The symbol type number to denote an empty symbol.
    enum { empty_symbol = -2 };

    /// Internal symbol number for tokens (subsumed by symbol_number_type).
    typedef unsigned char token_number_type;

    /// A complete symbol.
    ///
    /// Expects its Base type to provide access to the symbol type
    /// via type_get().
    ///
    /// Provide access to semantic value and location.
    template <typename Base>
    struct basic_symbol : Base
    {
      /// Alias to Base.
      typedef Base super_type;

      /// Default constructor.
      basic_symbol ();

      /// Copy constructor.
      basic_symbol (const basic_symbol& other);

      /// Constructor for valueless symbols.
      basic_symbol (typename Base::kind_type t,
                    const location_type& l);

      /// Constructor for symbols with semantic value.
      basic_symbol (typename Base::kind_type t,
                    const semantic_type& v,
                    const location_type& l);

      /// Destroy the symbol.
      ~basic_symbol ();

      /// Destroy contents, and record that is empty.
      void clear ();

      /// Whether empty.
      bool empty () const;

      /// Destructive move, \a s is emptied into this.
      void move (basic_symbol& s);

      /// The semantic value.
      semantic_type value;

      /// The location.
      location_type location;

    private:
      /// Assignment operator.
      basic_symbol& operator= (const basic_symbol& other);
    };

    /// Type access provider for token (enum) based symbols.
    struct by_type
    {
      /// Default constructor.
      by_type ();

      /// Copy constructor.
      by_type (const by_type& other);

      /// The symbol type as needed by the constructor.
      typedef token_type kind_type;

      /// Constructor from (external) token numbers.
      by_type (kind_type t);

      /// Record that this symbol is empty.
      void clear ();

      /// Steal the symbol type from \a that.
      void move (by_type& that);

      /// The (internal) type number (corresponding to \a type).
      /// \a empty when empty.
      symbol_number_type type_get () const;

      /// The token.
      token_type token () const;

      /// The symbol type.
      /// \a empty_symbol when empty.
      /// An int, not token_number_type, to be able to store empty_symbol.
      int type;
    };

    /// "External" symbols: returned by the scanner.
    typedef basic_symbol<by_type> symbol_type;


    /// Build a parser object.
    parser (CYDriver &driver_yyarg);
    virtual ~parser ();

    /// Parse.
    /// \returns  0 iff parsing succeeded.
    virtual int parse ();

#if YYDEBUG
    /// The current debugging stream.
    std::ostream& debug_stream () const YY_ATTRIBUTE_PURE;
    /// Set the current debugging stream.
    void set_debug_stream (std::ostream &);

    /// Type for debugging levels.
    typedef int debug_level_type;
    /// The current debugging level.
    debug_level_type debug_level () const YY_ATTRIBUTE_PURE;
    /// Set the current debugging level.
    void set_debug_level (debug_level_type l);
#endif

    /// Report a syntax error.
    /// \param loc    where the syntax error is found.
    /// \param msg    a description of the syntax error.
    virtual void error (const location_type& loc, const std::string& msg);

    /// Report a syntax error.
    void error (const syntax_error& err);

  private:
    /// This class is not copyable.
    parser (const parser&);
    parser& operator= (const parser&);

    /// State numbers.
    typedef int state_type;

    /// Generate an error message.
    /// \param yystate   the state where the error occurred.
    /// \param yyla      the lookahead token.
    virtual std::string yysyntax_error_ (state_type yystate,
                                         const symbol_type& yyla) const;

    /// Compute post-reduction state.
    /// \param yystate   the current state
    /// \param yysym     the nonterminal to push on the stack
    state_type yy_lr_goto_state_ (state_type yystate, int yysym);

    /// Whether the given \c yypact_ value indicates a defaulted state.
    /// \param yyvalue   the value to check
    static bool yy_pact_value_is_default_ (int yyvalue);

    /// Whether the given \c yytable_ value indicates a syntax error.
    /// \param yyvalue   the value to check
    static bool yy_table_value_is_error_ (int yyvalue);

    static const short int yypact_ninf_;
    static const short int yytable_ninf_;

    /// Convert a scanner token number \a t to a symbol number.
    static token_number_type yytranslate_ (int t);

    // Tables.
  // YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
  // STATE-NUM.
  static const short int yypact_[];

  // YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
  // Performed when YYTABLE does not specify something else to do.  Zero
  // means the default is an error.
  static const unsigned short int yydefact_[];

  // YYPGOTO[NTERM-NUM].
  static const short int yypgoto_[];

  // YYDEFGOTO[NTERM-NUM].
  static const short int yydefgoto_[];

  // YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
  // positive, shift that token.  If negative, reduce the rule whose
  // number is the opposite.  If YYTABLE_NINF, syntax error.
  static const short int yytable_[];

  static const short int yycheck_[];

  // YYSTOS[STATE-NUM] -- The (internal number of the) accessing
  // symbol of state STATE-NUM.
  static const unsigned short int yystos_[];

  // YYR1[YYN] -- Symbol number of symbol that rule YYN derives.
  static const unsigned short int yyr1_[];

  // YYR2[YYN] -- Number of symbols on the right hand side of rule YYN.
  static const unsigned char yyr2_[];


    /// Convert the symbol name \a n to a form suitable for a diagnostic.
    static std::string yytnamerr_ (const char *n);


    /// For a symbol, its name in clear.
    static const char* const yytname_[];
#if YYDEBUG
  // YYRLINE[YYN] -- Source line where rule number YYN was defined.
  static const unsigned short int yyrline_[];
    /// Report on the debug stream that the rule \a r is going to be reduced.
    virtual void yy_reduce_print_ (int r);
    /// Print the state stack on the debug stream.
    virtual void yystack_print_ ();

    // Debugging.
    int yydebug_;
    std::ostream* yycdebug_;

    /// \brief Display a symbol type, value and location.
    /// \param yyo    The output stream.
    /// \param yysym  The symbol.
    template <typename Base>
    void yy_print_ (std::ostream& yyo, const basic_symbol<Base>& yysym) const;
#endif

    /// \brief Reclaim the memory associated to a symbol.
    /// \param yymsg     Why this token is reclaimed.
    ///                  If null, print nothing.
    /// \param yysym     The symbol.
    template <typename Base>
    void yy_destroy_ (const char* yymsg, basic_symbol<Base>& yysym) const;

  private:
    /// Type access provider for state based symbols.
    struct by_state
    {
      /// Default constructor.
      by_state ();

      /// The symbol type as needed by the constructor.
      typedef state_type kind_type;

      /// Constructor.
      by_state (kind_type s);

      /// Copy constructor.
      by_state (const by_state& other);

      /// Record that this symbol is empty.
      void clear ();

      /// Steal the symbol type from \a that.
      void move (by_state& that);

      /// The (internal) type number (corresponding to \a state).
      /// \a empty_symbol when empty.
      symbol_number_type type_get () const;

      /// The state number used to denote an empty symbol.
      enum { empty_state = -1 };

      /// The state.
      /// \a empty when empty.
      state_type state;
    };

    /// "Internal" symbol: element of the stack.
    struct stack_symbol_type : basic_symbol<by_state>
    {
      /// Superclass.
      typedef basic_symbol<by_state> super_type;
      /// Construct an empty symbol.
      stack_symbol_type ();
      /// Steal the contents from \a sym to build this.
      stack_symbol_type (state_type s, symbol_type& sym);
      /// Assignment, needed by push_back.
      stack_symbol_type& operator= (const stack_symbol_type& that);
    };

    /// Stack type.
    typedef stack<stack_symbol_type> stack_type;

    /// The stack.
    stack_type yystack_;

    /// Push a new state on the stack.
    /// \param m    a debug message to display
    ///             if null, no trace is output.
    /// \param s    the symbol
    /// \warning the contents of \a s.value is stolen.
    void yypush_ (const char* m, stack_symbol_type& s);

    /// Push a new look ahead token on the state on the stack.
    /// \param m    a debug message to display
    ///             if null, no trace is output.
    /// \param s    the state
    /// \param sym  the symbol (for its value and location).
    /// \warning the contents of \a s.value is stolen.
    void yypush_ (const char* m, state_type s, symbol_type& sym);

    /// Pop \a n symbols the three stacks.
    void yypop_ (unsigned int n = 1);

    /// Constants.
    enum
    {
      yyeof_ = 0,
      yylast_ = 10066,     ///< Last index in yytable_.
      yynnts_ = 318,  ///< Number of nonterminal symbols.
      yyfinal_ = 27, ///< Termination state number.
      yyterror_ = 1,
      yyerrcode_ = 256,
      yyntokens_ = 185  ///< Number of tokens.
    };


    // User arguments.
    CYDriver &driver;
  };



} // cy
#line 778 "Parser.hpp" // lalr1.cc:392


// //                    "%code provides" blocks.
#line 99 "Parser.ypp" // lalr1.cc:392


struct YYSTYPE {
    cy::parser::semantic_type semantic_;
    hi::Value highlight_;
};

int cylex(YYSTYPE *, CYLocation *, void *);


#line 793 "Parser.hpp" // lalr1.cc:392


#endif // !YY_CY_PARSER_HPP_INCLUDED
