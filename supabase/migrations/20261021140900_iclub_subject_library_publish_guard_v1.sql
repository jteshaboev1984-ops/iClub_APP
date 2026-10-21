begin;
revoke update on private.iclub_subject_library from service_role;
revoke update on private.iclub_subject_library_releases from service_role;
do $safe$
begin
 if has_table_privilege('service_role','private.iclub_subject_library','UPDATE')
 or has_table_privilege('service_role','private.iclub_subject_library_releases','UPDATE')
 then raise exception 'direct_release_activation_not_locked'; end if;
end $safe$;
commit;