*"* use this source file for your ABAP unit test classes
CLASS ltcl_saa_fitgap_engine DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS deactivated_scope_item FOR TESTING.
    METHODS extra_custom_fields FOR TESTING.
    METHODS custom_code_risk FOR TESTING.
    METHODS multiple_rules_same_scope_item FOR TESTING.
    METHODS ordering_high_med_score_desc FOR TESTING.
    METHODS no_gap_when_matches_baseline FOR TESTING.

ENDCLASS.


CLASS ltcl_saa_fitgap_engine IMPLEMENTATION.

  METHOD deactivated_scope_item.

    DATA lt_actual TYPE zcl_saa_fitgap_engine=>ty_actual_tt.
    DATA lt_baseline TYPE zcl_saa_fitgap_engine=>ty_baseline_tt.

    lt_actual = VALUE #(
      (
        scope_item       = 'J45'
        is_active        = abap_false
        custom_fields    = 0
        custom_code_risk = 0
      )
    ).

    lt_baseline = VALUE #(
      (
        scope_item                = 'J45'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
    ).

    DATA(lt_gaps) = zcl_saa_fitgap_engine=>calculate_gaps(
      it_actual   = lt_actual
      it_baseline = lt_baseline ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_gaps )
      exp = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-gap_type
      exp = zcl_saa_fitgap_engine=>gc_gap_deactivated ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-severity
      exp = zcl_saa_fitgap_engine=>gc_severity_high ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-score
      exp = 80 ).

  ENDMETHOD.


  METHOD extra_custom_fields.

    DATA lt_actual TYPE zcl_saa_fitgap_engine=>ty_actual_tt.
    DATA lt_baseline TYPE zcl_saa_fitgap_engine=>ty_baseline_tt.

    lt_actual = VALUE #(
      (
        scope_item       = 'J45'
        is_active        = abap_true
        custom_fields    = 25
        custom_code_risk = 0
      )
    ).

    lt_baseline = VALUE #(
      (
        scope_item                = 'J45'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
    ).

    DATA(lt_gaps) = zcl_saa_fitgap_engine=>calculate_gaps(
      it_actual   = lt_actual
      it_baseline = lt_baseline ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_gaps )
      exp = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-gap_type
      exp = zcl_saa_fitgap_engine=>gc_gap_extra_custom ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-severity
      exp = zcl_saa_fitgap_engine=>gc_severity_high ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-score
      exp = 100 ).

  ENDMETHOD.


  METHOD custom_code_risk.

    DATA lt_actual TYPE zcl_saa_fitgap_engine=>ty_actual_tt.
    DATA lt_baseline TYPE zcl_saa_fitgap_engine=>ty_baseline_tt.

    lt_actual = VALUE #(
      (
        scope_item       = 'J45'
        is_active        = abap_true
        custom_fields    = 5
        custom_code_risk = 4
      )
    ).

    lt_baseline = VALUE #(
      (
        scope_item                = 'J45'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
    ).

    DATA(lt_gaps) = zcl_saa_fitgap_engine=>calculate_gaps(
      it_actual   = lt_actual
      it_baseline = lt_baseline ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_gaps )
      exp = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-gap_type
      exp = zcl_saa_fitgap_engine=>gc_gap_custom_code_risk ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-severity
      exp = zcl_saa_fitgap_engine=>gc_severity_high ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-score
      exp = 90 ).

  ENDMETHOD.


  METHOD multiple_rules_same_scope_item.

    DATA lt_actual TYPE zcl_saa_fitgap_engine=>ty_actual_tt.
    DATA lt_baseline TYPE zcl_saa_fitgap_engine=>ty_baseline_tt.

    lt_actual = VALUE #(
      (
        scope_item       = 'J45'
        is_active        = abap_false
        custom_fields    = 25
        custom_code_risk = 4
      )
    ).

    lt_baseline = VALUE #(
      (
        scope_item                = 'J45'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
    ).

    DATA(lt_gaps) = zcl_saa_fitgap_engine=>calculate_gaps(
      it_actual   = lt_actual
      it_baseline = lt_baseline ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_gaps )
      exp = 3 ).

    cl_abap_unit_assert=>assert_not_initial( lt_gaps ).

  ENDMETHOD.


  METHOD ordering_high_med_score_desc.

    DATA lt_actual TYPE zcl_saa_fitgap_engine=>ty_actual_tt.
    DATA lt_baseline TYPE zcl_saa_fitgap_engine=>ty_baseline_tt.

    lt_actual = VALUE #(
      (
        scope_item       = 'J45'
        is_active        = abap_true
        custom_fields    = 25
        custom_code_risk = 0
      )
      (
        scope_item       = 'M10'
        is_active        = abap_true
        custom_fields    = 12
        custom_code_risk = 2
      )
      (
        scope_item       = 'S01'
        is_active        = abap_false
        custom_fields    = 0
        custom_code_risk = 0
      )
    ).

    lt_baseline = VALUE #(
      (
        scope_item                = 'J45'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
      (
        scope_item                = 'M10'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
      (
        scope_item                = 'S01'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
    ).

    DATA(lt_gaps) = zcl_saa_fitgap_engine=>calculate_gaps(
      it_actual   = lt_actual
      it_baseline = lt_baseline ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-severity
      exp = zcl_saa_fitgap_engine=>gc_severity_high ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 1 ]-score
      exp = 100 ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 2 ]-severity
      exp = zcl_saa_fitgap_engine=>gc_severity_high ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_gaps[ 3 ]-severity
      exp = zcl_saa_fitgap_engine=>gc_severity_medium ).

  ENDMETHOD.


  METHOD no_gap_when_matches_baseline.

    DATA lt_actual TYPE zcl_saa_fitgap_engine=>ty_actual_tt.
    DATA lt_baseline TYPE zcl_saa_fitgap_engine=>ty_baseline_tt.

    lt_actual = VALUE #(
      (
        scope_item       = 'J45'
        is_active        = abap_true
        custom_fields    = 5
        custom_code_risk = 0
      )
    ).

    lt_baseline = VALUE #(
      (
        scope_item                = 'J45'
        required_active           = abap_true
        max_allowed_custom_fields = 10
      )
    ).

    DATA(lt_gaps) = zcl_saa_fitgap_engine=>calculate_gaps(
      it_actual   = lt_actual
      it_baseline = lt_baseline ).

    cl_abap_unit_assert=>assert_initial( lt_gaps ).

  ENDMETHOD.

ENDCLASS.
