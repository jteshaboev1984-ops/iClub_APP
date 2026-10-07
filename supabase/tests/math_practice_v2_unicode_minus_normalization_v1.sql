-- Mathematics Practice v2 Unicode-minus normalization regression
-- Run only after 20261007002000_math_practice_v2_unicode_minus_normalization_v1.sql.

do $$
begin
  if public.iclub_normalize_answer('  −1,6  ') <> '-1.6' then
    raise exception 'normalize_unicode_minus_decimal_failed';
  end if;

  if public.iclub_normalize_answer('–4') <> '-4' then
    raise exception 'normalize_en_dash_failed';
  end if;

  if public.iclub_normalize_answer('—8') <> '-8' then
    raise exception 'normalize_em_dash_failed';
  end if;

  if public.iclub_normalize_answer('  A   B  ') <> 'a b' then
    raise exception 'existing_whitespace_lowercase_behavior_regressed';
  end if;

  if not public.iclub_is_numeric('−1.6') then
    raise exception 'unicode_minus_numeric_failed';
  end if;

  if not public.iclub_is_numeric('–2,25') then
    raise exception 'unicode_minus_comma_numeric_failed';
  end if;

  if public.iclub_is_numeric('−') then
    raise exception 'bare_minus_must_not_be_numeric';
  end if;

  if public.iclub_is_numeric('1/2') then
    raise exception 'fraction_string_must_not_become_scalar_numeric';
  end if;

  if public.iclub_is_numeric('abc') then
    raise exception 'text_must_not_become_numeric';
  end if;
end;
$$;
