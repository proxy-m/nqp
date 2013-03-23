my $ops := QAST::Compiler.operations();

$ops.add_hll_op('nqp', 'preinc', -> $qastcomp, $op {
    my $var := $op[0];
    unless nqp::istype($var, QAST::Var) {
        nqp::die("Pre-increment can only work on a variable");
    }
    $qastcomp.as_post(QAST::Op.new(
        :op('bind'),
        $var,
        QAST::Op.new(
            :op('add_n'),
            $var,
            QAST::IVal.new( :value(1) )
        )));
});

$ops.add_hll_op('nqp', 'predec', -> $qastcomp, $op {
    my $var := $op[0];
    unless nqp::istype($var, QAST::Var) {
        nqp::die("Pre-decrement can only work on a variable");
    }
    $qastcomp.as_post(QAST::Op.new(
        :op('bind'),
        $var,
        QAST::Op.new(
            :op('sub_n'),
            $var,
            QAST::IVal.new( :value(1) )
        )));
});

$ops.add_hll_op('nqp', 'postinc', -> $qastcomp, $op {
    my $var := $op[0];
    my $tmp := QAST::Op.unique('tmp');
    unless nqp::istype($var, QAST::Var) {
        nqp::die("Post-increment can only work on a variable");
    }
    $qastcomp.as_post(QAST::Stmt.new(
        :resultchild(0),
        QAST::Op.new(
            :op('bind'),
            QAST::Var.new( :name($tmp), :scope('local'), :decl('var'), :returns($var.returns) ),
            $var
        ),
        QAST::Op.new(
            :op('bind'),
            $var,
            QAST::Op.new(
                :op('add_n'),
                QAST::Var.new( :name($tmp), :scope('local'), :returns($var.returns)  ),
                QAST::IVal.new( :value(1) )
            )
        )));
});

$ops.add_hll_op('nqp', 'postdec', -> $qastcomp, $op {
    my $var := $op[0];
    my $tmp := QAST::Op.unique('tmp');
    unless nqp::istype($var, QAST::Var) {
        nqp::die("Post-decrement can only work on a variable");
    }
    $qastcomp.as_post(QAST::Stmt.new(
        :resultchild(0),
        QAST::Op.new(
            :op('bind'),
            QAST::Var.new( :name($tmp), :scope('local'), :decl('var') ),
            $var
        ),
        QAST::Op.new(
            :op('bind'),
            $var,
            QAST::Op.new(
                :op('sub_n'),
                QAST::Var.new( :name($tmp), :scope('local') ),
                QAST::IVal.new( :value(1) )
            )
        )));
});

$ops.add_hll_pirop_mapping('nqp', 'numify', 'smart_numify', 'NP');

$ops.add_hll_op('nqp', 'stringify', -> $qastcomp, $op {
    $qastcomp.as_post($op[0], :want('s'))
});

$ops.add_hll_op('nqp', 'eqaddr', -> $qastcomp, $op {
    $qastcomp.as_post(QAST::Op.new(
        :op('iseq_i'),
        QAST::Op.new( :op('where'), $op[0] ),
        QAST::Op.new( :op('where'), $op[1] )
    ))
});

$ops.add_hll_op('nqp', 'falsey', -> $qastcomp, $op {
    my $res := $*REGALLOC.fresh_i();
    my $ops := PIRT::Ops.new(:result($res));
    my $arg_post := $qastcomp.as_post($op[0]);
    if nqp::lc($qastcomp.infer_type($arg_post.result)) eq 'i' {
        $ops.push($arg_post);
        $ops.push_pirop('not', $res, $arg_post);
    }
    else {
        $arg_post := $qastcomp.coerce($arg_post, 'P');
        $ops.push($arg_post);
        $ops.push_pirop('isfalse', $res, $arg_post);
    }
    $ops
});
