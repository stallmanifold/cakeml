signature ml_translatorSyntax =
sig
  include Abbrev

  val mk_Eval   : term * term * term -> term
  val dest_Eval : term -> term * term * term
  val is_Eval   : term -> bool
  val Eval      : term

  val mk_DeclAssum   : term * term * term * term -> term
  val dest_DeclAssum : term -> term * term * term * term
  val is_DeclAssum   : term -> bool
  val DeclAssum      : term

  val mk_EqualityType   : term -> term
  val dest_EqualityType : term -> term
  val is_EqualityType   : term -> bool
  val EqualityType      : term

  val mk_CONTAINER   : term -> term
  val dest_CONTAINER : term -> term
  val is_CONTAINER   : term -> bool
  val CONTAINER      : term

  val mk_PRECONDITION   : term -> term
  val dest_PRECONDITION : term -> term
  val is_PRECONDITION   : term -> bool
  val PRECONDITION      : term

  val mk_TAG   : term * term -> term
  val dest_TAG : term -> term * term
  val is_TAG   : term -> bool

  val mk_Eq   : term * term * term * term -> term
  val dest_Eq : term -> term * term * term * term
  val is_Eq   : term -> bool
  val Eq      : term

  val mk_PreImp   : term * term -> term
  val dest_PreImp : term -> term * term
  val is_PreImp   : term -> bool

  val mk_vector_type   : hol_type -> hol_type
  val dest_vector_type : hol_type -> hol_type
  val is_vector_type   : hol_type -> bool

  val TRUE  : term
  val FALSE : term

  val BOOL        : term
  val WORD8       : term
  val NUM         : term
  val INT         : term
  val CHAR        : term
  val STRING_TYPE : term
  val UNIT_TYPE   : term
  val LIST_TYPE   : term

  val mk_LIST_TYPE   : term * term * term -> term
  val dest_LIST_TYPE : term -> term * term * term
  val is_LIST_TYPE   : term -> bool

  val mk_Arrow   : term * term * term * term -> term
  val dest_Arrow : term -> term * term * term * term
  val is_Arrow   : term -> bool
  val Arrow      : term
end
