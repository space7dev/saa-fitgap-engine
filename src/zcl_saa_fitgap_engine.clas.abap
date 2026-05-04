CLASS zcl_saa_fitgap_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_scope_item TYPE c LENGTH 10.
    TYPES ty_severity   TYPE c LENGTH 1.
    TYPES ty_gap_type   TYPE c LENGTH 30.

    TYPES:
      BEGIN OF ty_actual,
        scope_item       TYPE ty_scope_item,
        is_active        TYPE abap_bool,
        custom_fields    TYPE i,
        custom_code_risk TYPE i,
      END OF ty_actual.

    TYPES ty_actual_tt TYPE STANDARD TABLE OF ty_actual WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_baseline,
        scope_item                TYPE ty_scope_item,
        required_active           TYPE abap_bool,
        max_allowed_custom_fields TYPE i,
      END OF ty_baseline.

    TYPES ty_baseline_tt TYPE STANDARD TABLE OF ty_baseline WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_gap,
        scope_item TYPE ty_scope_item,
        gap_type   TYPE ty_gap_type,
        severity   TYPE ty_severity,
        score      TYPE i,
        reason     TYPE string,
      END OF ty_gap.

    TYPES ty_gap_tt TYPE STANDARD TABLE OF ty_gap WITH EMPTY KEY.

    CONSTANTS:
      gc_gap_deactivated      TYPE ty_gap_type VALUE 'DEACTIVATED',
      gc_gap_extra_custom     TYPE ty_gap_type VALUE 'EXTRA_CUSTOM',
      gc_gap_custom_code_risk TYPE ty_gap_type VALUE 'CUSTOM_CODE_RISK'.

    CONSTANTS:
      gc_severity_high   TYPE ty_severity VALUE 'H',
      gc_severity_medium TYPE ty_severity VALUE 'M',
      gc_severity_low    TYPE ty_severity VALUE 'L'.

    CLASS-METHODS calculate_gaps
      IMPORTING
        it_actual   TYPE ty_actual_tt
        it_baseline TYPE ty_baseline_tt
      RETURNING
        VALUE(rt_gaps) TYPE ty_gap_tt.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_baseline_hash,
        scope_item                TYPE ty_scope_item,
        required_active           TYPE abap_bool,
        max_allowed_custom_fields TYPE i,
      END OF ty_baseline_hash.

    TYPES ty_baseline_hash_tt TYPE HASHED TABLE OF ty_baseline_hash
      WITH UNIQUE KEY scope_item.

    CLASS-METHODS build_baseline_index
      IMPORTING
        it_baseline TYPE ty_baseline_tt
      RETURNING
        VALUE(rt_baseline_index) TYPE ty_baseline_hash_tt.

    CLASS-METHODS evaluate_deactivated
      IMPORTING
        is_actual   TYPE ty_actual
        is_baseline TYPE ty_baseline_hash
      CHANGING
        ct_gaps     TYPE ty_gap_tt.

    CLASS-METHODS evaluate_extra_custom
      IMPORTING
        is_actual   TYPE ty_actual
        is_baseline TYPE ty_baseline_hash
      CHANGING
        ct_gaps     TYPE ty_gap_tt.

    CLASS-METHODS evaluate_custom_code_risk
      IMPORTING
        is_actual TYPE ty_actual
      CHANGING
        ct_gaps   TYPE ty_gap_tt.

    CLASS-METHODS add_gap
      IMPORTING
        iv_scope_item TYPE ty_scope_item
        iv_gap_type   TYPE ty_gap_type
        iv_severity   TYPE ty_severity
        iv_score      TYPE i
        iv_reason     TYPE string
      CHANGING
        ct_gaps       TYPE ty_gap_tt.

    CLASS-METHODS sort_gaps
      CHANGING
        ct_gaps TYPE ty_gap_tt.

ENDCLASS.


CLASS zcl_saa_fitgap_engine IMPLEMENTATION.

  METHOD calculate_gaps.

    DATA lt_baseline_index TYPE ty_baseline_hash_tt.

    lt_baseline_index = build_baseline_index( it_baseline ).

    LOOP AT it_actual INTO DATA(ls_actual).

      READ TABLE lt_baseline_index INTO DATA(ls_baseline)
        WITH TABLE KEY scope_item = ls_actual-scope_item.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      evaluate_deactivated(
        EXPORTING
          is_actual   = ls_actual
          is_baseline = ls_baseline
        CHANGING
          ct_gaps     = rt_gaps ).

      evaluate_extra_custom(
        EXPORTING
          is_actual   = ls_actual
          is_baseline = ls_baseline
        CHANGING
          ct_gaps     = rt_gaps ).

      evaluate_custom_code_risk(
        EXPORTING
          is_actual = ls_actual
        CHANGING
          ct_gaps   = rt_gaps ).

    ENDLOOP.

    sort_gaps( CHANGING ct_gaps = rt_gaps ).

  ENDMETHOD.


  METHOD build_baseline_index.

    LOOP AT it_baseline INTO DATA(ls_baseline).
      INSERT VALUE ty_baseline_hash(
        scope_item                = ls_baseline-scope_item
        required_active           = ls_baseline-required_active
        max_allowed_custom_fields = ls_baseline-max_allowed_custom_fields
      ) INTO TABLE rt_baseline_index.
    ENDLOOP.

  ENDMETHOD.


  METHOD evaluate_deactivated.

    IF is_baseline-required_active = abap_true
       AND is_actual-is_active = abap_false.

      add_gap(
        EXPORTING
          iv_scope_item = is_actual-scope_item
          iv_gap_type   = gc_gap_deactivated
          iv_severity   = gc_severity_high
          iv_score      = 80
          iv_reason     = |Scope item { is_actual-scope_item } is required by baseline but inactive in actual.|
        CHANGING
          ct_gaps       = ct_gaps ).

    ENDIF.

  ENDMETHOD.


  METHOD evaluate_extra_custom.

    IF is_actual-custom_fields > is_baseline-max_allowed_custom_fields.

      DATA(lv_overage) = is_actual-custom_fields - is_baseline-max_allowed_custom_fields.
      DATA(lv_score) = 40 + lv_overage * 10.

      IF lv_score > 100.
        lv_score = 100.
      ENDIF.

      DATA(lv_severity) = gc_severity_medium.

      IF is_actual-custom_fields > is_baseline-max_allowed_custom_fields * 2.
        lv_severity = gc_severity_high.
      ENDIF.

      add_gap(
        EXPORTING
          iv_scope_item = is_actual-scope_item
          iv_gap_type   = gc_gap_extra_custom
          iv_severity   = lv_severity
          iv_score      = lv_score
          iv_reason     = |Actual custom fields { is_actual-custom_fields } exceed allowed baseline { is_baseline-max_allowed_custom_fields }.|
        CHANGING
          ct_gaps       = ct_gaps ).

    ENDIF.

  ENDMETHOD.


  METHOD evaluate_custom_code_risk.

    IF is_actual-custom_code_risk > 0.

      DATA(lv_score) = 30 + is_actual-custom_code_risk * 15.

      IF lv_score > 95.
        lv_score = 95.
      ENDIF.

      DATA(lv_severity) = gc_severity_medium.

      IF is_actual-custom_code_risk >= 4.
        lv_severity = gc_severity_high.
      ENDIF.

      add_gap(
        EXPORTING
          iv_scope_item = is_actual-scope_item
          iv_gap_type   = gc_gap_custom_code_risk
          iv_severity   = lv_severity
          iv_score      = lv_score
          iv_reason     = |Custom code risk is { is_actual-custom_code_risk }.|
        CHANGING
          ct_gaps       = ct_gaps ).

    ENDIF.

  ENDMETHOD.


  METHOD add_gap.

    APPEND VALUE ty_gap(
      scope_item = iv_scope_item
      gap_type   = iv_gap_type
      severity   = iv_severity
      score      = iv_score
      reason     = iv_reason
    ) TO ct_gaps.

  ENDMETHOD.


  METHOD sort_gaps.

    DATA lt_sorted TYPE ty_gap_tt.
    DATA lt_medium TYPE ty_gap_tt.
    DATA lt_low    TYPE ty_gap_tt.

    LOOP AT ct_gaps INTO DATA(ls_gap_high) WHERE severity = gc_severity_high.
      APPEND ls_gap_high TO lt_sorted.
    ENDLOOP.

    SORT lt_sorted BY score DESCENDING scope_item ASCENDING gap_type ASCENDING.

    LOOP AT ct_gaps INTO DATA(ls_gap_medium) WHERE severity = gc_severity_medium.
      APPEND ls_gap_medium TO lt_medium.
    ENDLOOP.

    SORT lt_medium BY score DESCENDING scope_item ASCENDING gap_type ASCENDING.
    APPEND LINES OF lt_medium TO lt_sorted.

    LOOP AT ct_gaps INTO DATA(ls_gap_low) WHERE severity = gc_severity_low.
      APPEND ls_gap_low TO lt_low.
    ENDLOOP.

    SORT lt_low BY score DESCENDING scope_item ASCENDING gap_type ASCENDING.
    APPEND LINES OF lt_low TO lt_sorted.

    ct_gaps = lt_sorted.

  ENDMETHOD.

ENDCLASS.
