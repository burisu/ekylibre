# Migration generated with nomenclature migration #20150919123840
class FixPlantVariety < ActiveRecord::Migration[4.2]
  def up
    # Change item varieties#avena_evora with {:name=>"avena_sativa_evora", :parent=>"avena_sativa"}
    execute "UPDATE activities SET cultivation_variety='avena_sativa_evora' WHERE cultivation_variety='avena_evora'"
    execute "UPDATE activities SET support_variety='avena_sativa_evora' WHERE support_variety='avena_evora'"
    execute "UPDATE products SET variety='avena_sativa_evora' WHERE variety='avena_evora'"
    execute "UPDATE products SET derivative_of='avena_sativa_evora' WHERE derivative_of='avena_evora'"
    execute "UPDATE product_nature_variants SET variety='avena_sativa_evora' WHERE variety='avena_evora'"
    execute "UPDATE product_nature_variants SET derivative_of='avena_sativa_evora' WHERE derivative_of='avena_evora'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='avena_sativa_evora' WHERE cultivation_variety='avena_evora'"
    execute "UPDATE product_natures SET variety='avena_sativa_evora' WHERE variety='avena_evora'"
    execute "UPDATE product_natures SET derivative_of='avena_sativa_evora' WHERE derivative_of='avena_evora'"
    # Change item varieties#avena_une_de_mai with {:name=>"avena_sativa_une_de_mai", :parent=>"avena_sativa"}
    execute "UPDATE activities SET cultivation_variety='avena_sativa_une_de_mai' WHERE cultivation_variety='avena_une_de_mai'"
    execute "UPDATE activities SET support_variety='avena_sativa_une_de_mai' WHERE support_variety='avena_une_de_mai'"
    execute "UPDATE products SET variety='avena_sativa_une_de_mai' WHERE variety='avena_une_de_mai'"
    execute "UPDATE products SET derivative_of='avena_sativa_une_de_mai' WHERE derivative_of='avena_une_de_mai'"
    execute "UPDATE product_nature_variants SET variety='avena_sativa_une_de_mai' WHERE variety='avena_une_de_mai'"
    execute "UPDATE product_nature_variants SET derivative_of='avena_sativa_une_de_mai' WHERE derivative_of='avena_une_de_mai'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='avena_sativa_une_de_mai' WHERE cultivation_variety='avena_une_de_mai'"
    execute "UPDATE product_natures SET variety='avena_sativa_une_de_mai' WHERE variety='avena_une_de_mai'"
    execute "UPDATE product_natures SET derivative_of='avena_sativa_une_de_mai' WHERE derivative_of='avena_une_de_mai'"
    # Change item varieties#citrullus_lanatus_gigérine with {:name=>"citrullus_lanatus_gigerine"}
    execute "UPDATE activities SET cultivation_variety='citrullus_lanatus_gigerine' WHERE cultivation_variety='citrullus_lanatus_gigérine'"
    execute "UPDATE activities SET support_variety='citrullus_lanatus_gigerine' WHERE support_variety='citrullus_lanatus_gigérine'"
    execute "UPDATE products SET variety='citrullus_lanatus_gigerine' WHERE variety='citrullus_lanatus_gigérine'"
    execute "UPDATE products SET derivative_of='citrullus_lanatus_gigerine' WHERE derivative_of='citrullus_lanatus_gigérine'"
    execute "UPDATE product_nature_variants SET variety='citrullus_lanatus_gigerine' WHERE variety='citrullus_lanatus_gigérine'"
    execute "UPDATE product_nature_variants SET derivative_of='citrullus_lanatus_gigerine' WHERE derivative_of='citrullus_lanatus_gigérine'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='citrullus_lanatus_gigerine' WHERE cultivation_variety='citrullus_lanatus_gigérine'"
    execute "UPDATE product_natures SET variety='citrullus_lanatus_gigerine' WHERE variety='citrullus_lanatus_gigérine'"
    execute "UPDATE product_natures SET derivative_of='citrullus_lanatus_gigerine' WHERE derivative_of='citrullus_lanatus_gigérine'"
    # Change item varieties#medicago_comete with {:name=>"medicago_sativa_comete", :parent=>"medicago_sativa"}
    execute "UPDATE activities SET cultivation_variety='medicago_sativa_comete' WHERE cultivation_variety='medicago_comete'"
    execute "UPDATE activities SET support_variety='medicago_sativa_comete' WHERE support_variety='medicago_comete'"
    execute "UPDATE products SET variety='medicago_sativa_comete' WHERE variety='medicago_comete'"
    execute "UPDATE products SET derivative_of='medicago_sativa_comete' WHERE derivative_of='medicago_comete'"
    execute "UPDATE product_nature_variants SET variety='medicago_sativa_comete' WHERE variety='medicago_comete'"
    execute "UPDATE product_nature_variants SET derivative_of='medicago_sativa_comete' WHERE derivative_of='medicago_comete'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='medicago_sativa_comete' WHERE cultivation_variety='medicago_comete'"
    execute "UPDATE product_natures SET variety='medicago_sativa_comete' WHERE variety='medicago_comete'"
    execute "UPDATE product_natures SET derivative_of='medicago_sativa_comete' WHERE derivative_of='medicago_comete'"
    # Merge item varieties#pisum_vernum into pisum_sativum
    execute "UPDATE activities SET cultivation_variety='pisum_sativum' WHERE cultivation_variety='pisum_vernum'"
    execute "UPDATE activities SET support_variety='pisum_sativum' WHERE support_variety='pisum_vernum'"
    execute "UPDATE products SET variety='pisum_sativum' WHERE variety='pisum_vernum'"
    execute "UPDATE products SET derivative_of='pisum_sativum' WHERE derivative_of='pisum_vernum'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum' WHERE variety='pisum_vernum'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum' WHERE derivative_of='pisum_vernum'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum' WHERE cultivation_variety='pisum_vernum'"
    execute "UPDATE product_natures SET variety='pisum_sativum' WHERE variety='pisum_vernum'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum' WHERE derivative_of='pisum_vernum'"
    # Merge item varieties#pisum_hibernum into pisum_sativum
    execute "UPDATE activities SET cultivation_variety='pisum_sativum' WHERE cultivation_variety='pisum_hibernum'"
    execute "UPDATE activities SET support_variety='pisum_sativum' WHERE support_variety='pisum_hibernum'"
    execute "UPDATE products SET variety='pisum_sativum' WHERE variety='pisum_hibernum'"
    execute "UPDATE products SET derivative_of='pisum_sativum' WHERE derivative_of='pisum_hibernum'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum' WHERE variety='pisum_hibernum'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum' WHERE derivative_of='pisum_hibernum'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum' WHERE cultivation_variety='pisum_hibernum'"
    execute "UPDATE product_natures SET variety='pisum_sativum' WHERE variety='pisum_hibernum'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum' WHERE derivative_of='pisum_hibernum'"
    # Change item varieties#pisum_vernum_astronaute with {:name=>"pisum_sativum_astronaute"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_astronaute' WHERE cultivation_variety='pisum_vernum_astronaute'"
    execute "UPDATE activities SET support_variety='pisum_sativum_astronaute' WHERE support_variety='pisum_vernum_astronaute'"
    execute "UPDATE products SET variety='pisum_sativum_astronaute' WHERE variety='pisum_vernum_astronaute'"
    execute "UPDATE products SET derivative_of='pisum_sativum_astronaute' WHERE derivative_of='pisum_vernum_astronaute'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_astronaute' WHERE variety='pisum_vernum_astronaute'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_astronaute' WHERE derivative_of='pisum_vernum_astronaute'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_astronaute' WHERE cultivation_variety='pisum_vernum_astronaute'"
    execute "UPDATE product_natures SET variety='pisum_sativum_astronaute' WHERE variety='pisum_vernum_astronaute'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_astronaute' WHERE derivative_of='pisum_vernum_astronaute'"
    # Change item varieties#pisum_vernum_audit with {:name=>"pisum_sativum_audit"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_audit' WHERE cultivation_variety='pisum_vernum_audit'"
    execute "UPDATE activities SET support_variety='pisum_sativum_audit' WHERE support_variety='pisum_vernum_audit'"
    execute "UPDATE products SET variety='pisum_sativum_audit' WHERE variety='pisum_vernum_audit'"
    execute "UPDATE products SET derivative_of='pisum_sativum_audit' WHERE derivative_of='pisum_vernum_audit'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_audit' WHERE variety='pisum_vernum_audit'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_audit' WHERE derivative_of='pisum_vernum_audit'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_audit' WHERE cultivation_variety='pisum_vernum_audit'"
    execute "UPDATE product_natures SET variety='pisum_sativum_audit' WHERE variety='pisum_vernum_audit'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_audit' WHERE derivative_of='pisum_vernum_audit'"
    # Change item varieties#pisum_vernum_kayanne with {:name=>"pisum_sativum_kayanne"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_kayanne' WHERE cultivation_variety='pisum_vernum_kayanne'"
    execute "UPDATE activities SET support_variety='pisum_sativum_kayanne' WHERE support_variety='pisum_vernum_kayanne'"
    execute "UPDATE products SET variety='pisum_sativum_kayanne' WHERE variety='pisum_vernum_kayanne'"
    execute "UPDATE products SET derivative_of='pisum_sativum_kayanne' WHERE derivative_of='pisum_vernum_kayanne'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_kayanne' WHERE variety='pisum_vernum_kayanne'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_kayanne' WHERE derivative_of='pisum_vernum_kayanne'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_kayanne' WHERE cultivation_variety='pisum_vernum_kayanne'"
    execute "UPDATE product_natures SET variety='pisum_sativum_kayanne' WHERE variety='pisum_vernum_kayanne'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_kayanne' WHERE derivative_of='pisum_vernum_kayanne'"
    # Change item varieties#pisum_vernum_mowgli with {:name=>"pisum_sativum_mowgli"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_mowgli' WHERE cultivation_variety='pisum_vernum_mowgli'"
    execute "UPDATE activities SET support_variety='pisum_sativum_mowgli' WHERE support_variety='pisum_vernum_mowgli'"
    execute "UPDATE products SET variety='pisum_sativum_mowgli' WHERE variety='pisum_vernum_mowgli'"
    execute "UPDATE products SET derivative_of='pisum_sativum_mowgli' WHERE derivative_of='pisum_vernum_mowgli'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_mowgli' WHERE variety='pisum_vernum_mowgli'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_mowgli' WHERE derivative_of='pisum_vernum_mowgli'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_mowgli' WHERE cultivation_variety='pisum_vernum_mowgli'"
    execute "UPDATE product_natures SET variety='pisum_sativum_mowgli' WHERE variety='pisum_vernum_mowgli'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_mowgli' WHERE derivative_of='pisum_vernum_mowgli'"
    # Change item varieties#pisum_vernum_mythic with {:name=>"pisum_sativum_mythic"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_mythic' WHERE cultivation_variety='pisum_vernum_mythic'"
    execute "UPDATE activities SET support_variety='pisum_sativum_mythic' WHERE support_variety='pisum_vernum_mythic'"
    execute "UPDATE products SET variety='pisum_sativum_mythic' WHERE variety='pisum_vernum_mythic'"
    execute "UPDATE products SET derivative_of='pisum_sativum_mythic' WHERE derivative_of='pisum_vernum_mythic'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_mythic' WHERE variety='pisum_vernum_mythic'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_mythic' WHERE derivative_of='pisum_vernum_mythic'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_mythic' WHERE cultivation_variety='pisum_vernum_mythic'"
    execute "UPDATE product_natures SET variety='pisum_sativum_mythic' WHERE variety='pisum_vernum_mythic'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_mythic' WHERE derivative_of='pisum_vernum_mythic'"
    # Change item varieties#pisum_vernum_navarro with {:name=>"pisum_sativum_navarro"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_navarro' WHERE cultivation_variety='pisum_vernum_navarro'"
    execute "UPDATE activities SET support_variety='pisum_sativum_navarro' WHERE support_variety='pisum_vernum_navarro'"
    execute "UPDATE products SET variety='pisum_sativum_navarro' WHERE variety='pisum_vernum_navarro'"
    execute "UPDATE products SET derivative_of='pisum_sativum_navarro' WHERE derivative_of='pisum_vernum_navarro'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_navarro' WHERE variety='pisum_vernum_navarro'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_navarro' WHERE derivative_of='pisum_vernum_navarro'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_navarro' WHERE cultivation_variety='pisum_vernum_navarro'"
    execute "UPDATE product_natures SET variety='pisum_sativum_navarro' WHERE variety='pisum_vernum_navarro'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_navarro' WHERE derivative_of='pisum_vernum_navarro'"
    # Change item varieties#pisum_vernum_onyx with {:name=>"pisum_sativum_onyx"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_onyx' WHERE cultivation_variety='pisum_vernum_onyx'"
    execute "UPDATE activities SET support_variety='pisum_sativum_onyx' WHERE support_variety='pisum_vernum_onyx'"
    execute "UPDATE products SET variety='pisum_sativum_onyx' WHERE variety='pisum_vernum_onyx'"
    execute "UPDATE products SET derivative_of='pisum_sativum_onyx' WHERE derivative_of='pisum_vernum_onyx'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_onyx' WHERE variety='pisum_vernum_onyx'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_onyx' WHERE derivative_of='pisum_vernum_onyx'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_onyx' WHERE cultivation_variety='pisum_vernum_onyx'"
    execute "UPDATE product_natures SET variety='pisum_sativum_onyx' WHERE variety='pisum_vernum_onyx'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_onyx' WHERE derivative_of='pisum_vernum_onyx'"
    # Change item varieties#pisum_vernum_rocket with {:name=>"pisum_sativum_rocket"}
    execute "UPDATE activities SET cultivation_variety='pisum_sativum_rocket' WHERE cultivation_variety='pisum_vernum_rocket'"
    execute "UPDATE activities SET support_variety='pisum_sativum_rocket' WHERE support_variety='pisum_vernum_rocket'"
    execute "UPDATE products SET variety='pisum_sativum_rocket' WHERE variety='pisum_vernum_rocket'"
    execute "UPDATE products SET derivative_of='pisum_sativum_rocket' WHERE derivative_of='pisum_vernum_rocket'"
    execute "UPDATE product_nature_variants SET variety='pisum_sativum_rocket' WHERE variety='pisum_vernum_rocket'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_sativum_rocket' WHERE derivative_of='pisum_vernum_rocket'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_sativum_rocket' WHERE cultivation_variety='pisum_vernum_rocket'"
    execute "UPDATE product_natures SET variety='pisum_sativum_rocket' WHERE variety='pisum_vernum_rocket'"
    execute "UPDATE product_natures SET derivative_of='pisum_sativum_rocket' WHERE derivative_of='pisum_vernum_rocket'"
  end

  def down
    # Reverse: Change item varieties#pisum_vernum_rocket with {:name=>"pisum_sativum_rocket"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_rocket' WHERE derivative_of='pisum_sativum_rocket'"
    execute "UPDATE product_natures SET variety='pisum_vernum_rocket' WHERE variety='pisum_sativum_rocket'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_rocket' WHERE cultivation_variety='pisum_sativum_rocket'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_rocket' WHERE derivative_of='pisum_sativum_rocket'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_rocket' WHERE variety='pisum_sativum_rocket'"
    execute "UPDATE products SET derivative_of='pisum_vernum_rocket' WHERE derivative_of='pisum_sativum_rocket'"
    execute "UPDATE products SET variety='pisum_vernum_rocket' WHERE variety='pisum_sativum_rocket'"
    execute "UPDATE activities SET support_variety='pisum_vernum_rocket' WHERE support_variety='pisum_sativum_rocket'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_rocket' WHERE cultivation_variety='pisum_sativum_rocket'"
    # Reverse: Change item varieties#pisum_vernum_onyx with {:name=>"pisum_sativum_onyx"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_onyx' WHERE derivative_of='pisum_sativum_onyx'"
    execute "UPDATE product_natures SET variety='pisum_vernum_onyx' WHERE variety='pisum_sativum_onyx'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_onyx' WHERE cultivation_variety='pisum_sativum_onyx'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_onyx' WHERE derivative_of='pisum_sativum_onyx'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_onyx' WHERE variety='pisum_sativum_onyx'"
    execute "UPDATE products SET derivative_of='pisum_vernum_onyx' WHERE derivative_of='pisum_sativum_onyx'"
    execute "UPDATE products SET variety='pisum_vernum_onyx' WHERE variety='pisum_sativum_onyx'"
    execute "UPDATE activities SET support_variety='pisum_vernum_onyx' WHERE support_variety='pisum_sativum_onyx'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_onyx' WHERE cultivation_variety='pisum_sativum_onyx'"
    # Reverse: Change item varieties#pisum_vernum_navarro with {:name=>"pisum_sativum_navarro"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_navarro' WHERE derivative_of='pisum_sativum_navarro'"
    execute "UPDATE product_natures SET variety='pisum_vernum_navarro' WHERE variety='pisum_sativum_navarro'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_navarro' WHERE cultivation_variety='pisum_sativum_navarro'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_navarro' WHERE derivative_of='pisum_sativum_navarro'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_navarro' WHERE variety='pisum_sativum_navarro'"
    execute "UPDATE products SET derivative_of='pisum_vernum_navarro' WHERE derivative_of='pisum_sativum_navarro'"
    execute "UPDATE products SET variety='pisum_vernum_navarro' WHERE variety='pisum_sativum_navarro'"
    execute "UPDATE activities SET support_variety='pisum_vernum_navarro' WHERE support_variety='pisum_sativum_navarro'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_navarro' WHERE cultivation_variety='pisum_sativum_navarro'"
    # Reverse: Change item varieties#pisum_vernum_mythic with {:name=>"pisum_sativum_mythic"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_mythic' WHERE derivative_of='pisum_sativum_mythic'"
    execute "UPDATE product_natures SET variety='pisum_vernum_mythic' WHERE variety='pisum_sativum_mythic'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_mythic' WHERE cultivation_variety='pisum_sativum_mythic'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_mythic' WHERE derivative_of='pisum_sativum_mythic'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_mythic' WHERE variety='pisum_sativum_mythic'"
    execute "UPDATE products SET derivative_of='pisum_vernum_mythic' WHERE derivative_of='pisum_sativum_mythic'"
    execute "UPDATE products SET variety='pisum_vernum_mythic' WHERE variety='pisum_sativum_mythic'"
    execute "UPDATE activities SET support_variety='pisum_vernum_mythic' WHERE support_variety='pisum_sativum_mythic'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_mythic' WHERE cultivation_variety='pisum_sativum_mythic'"
    # Reverse: Change item varieties#pisum_vernum_mowgli with {:name=>"pisum_sativum_mowgli"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_mowgli' WHERE derivative_of='pisum_sativum_mowgli'"
    execute "UPDATE product_natures SET variety='pisum_vernum_mowgli' WHERE variety='pisum_sativum_mowgli'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_mowgli' WHERE cultivation_variety='pisum_sativum_mowgli'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_mowgli' WHERE derivative_of='pisum_sativum_mowgli'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_mowgli' WHERE variety='pisum_sativum_mowgli'"
    execute "UPDATE products SET derivative_of='pisum_vernum_mowgli' WHERE derivative_of='pisum_sativum_mowgli'"
    execute "UPDATE products SET variety='pisum_vernum_mowgli' WHERE variety='pisum_sativum_mowgli'"
    execute "UPDATE activities SET support_variety='pisum_vernum_mowgli' WHERE support_variety='pisum_sativum_mowgli'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_mowgli' WHERE cultivation_variety='pisum_sativum_mowgli'"
    # Reverse: Change item varieties#pisum_vernum_kayanne with {:name=>"pisum_sativum_kayanne"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_kayanne' WHERE derivative_of='pisum_sativum_kayanne'"
    execute "UPDATE product_natures SET variety='pisum_vernum_kayanne' WHERE variety='pisum_sativum_kayanne'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_kayanne' WHERE cultivation_variety='pisum_sativum_kayanne'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_kayanne' WHERE derivative_of='pisum_sativum_kayanne'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_kayanne' WHERE variety='pisum_sativum_kayanne'"
    execute "UPDATE products SET derivative_of='pisum_vernum_kayanne' WHERE derivative_of='pisum_sativum_kayanne'"
    execute "UPDATE products SET variety='pisum_vernum_kayanne' WHERE variety='pisum_sativum_kayanne'"
    execute "UPDATE activities SET support_variety='pisum_vernum_kayanne' WHERE support_variety='pisum_sativum_kayanne'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_kayanne' WHERE cultivation_variety='pisum_sativum_kayanne'"
    # Reverse: Change item varieties#pisum_vernum_audit with {:name=>"pisum_sativum_audit"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_audit' WHERE derivative_of='pisum_sativum_audit'"
    execute "UPDATE product_natures SET variety='pisum_vernum_audit' WHERE variety='pisum_sativum_audit'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_audit' WHERE cultivation_variety='pisum_sativum_audit'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_audit' WHERE derivative_of='pisum_sativum_audit'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_audit' WHERE variety='pisum_sativum_audit'"
    execute "UPDATE products SET derivative_of='pisum_vernum_audit' WHERE derivative_of='pisum_sativum_audit'"
    execute "UPDATE products SET variety='pisum_vernum_audit' WHERE variety='pisum_sativum_audit'"
    execute "UPDATE activities SET support_variety='pisum_vernum_audit' WHERE support_variety='pisum_sativum_audit'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_audit' WHERE cultivation_variety='pisum_sativum_audit'"
    # Reverse: Change item varieties#pisum_vernum_astronaute with {:name=>"pisum_sativum_astronaute"}
    execute "UPDATE product_natures SET derivative_of='pisum_vernum_astronaute' WHERE derivative_of='pisum_sativum_astronaute'"
    execute "UPDATE product_natures SET variety='pisum_vernum_astronaute' WHERE variety='pisum_sativum_astronaute'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pisum_vernum_astronaute' WHERE cultivation_variety='pisum_sativum_astronaute'"
    execute "UPDATE product_nature_variants SET derivative_of='pisum_vernum_astronaute' WHERE derivative_of='pisum_sativum_astronaute'"
    execute "UPDATE product_nature_variants SET variety='pisum_vernum_astronaute' WHERE variety='pisum_sativum_astronaute'"
    execute "UPDATE products SET derivative_of='pisum_vernum_astronaute' WHERE derivative_of='pisum_sativum_astronaute'"
    execute "UPDATE products SET variety='pisum_vernum_astronaute' WHERE variety='pisum_sativum_astronaute'"
    execute "UPDATE activities SET support_variety='pisum_vernum_astronaute' WHERE support_variety='pisum_sativum_astronaute'"
    execute "UPDATE activities SET cultivation_variety='pisum_vernum_astronaute' WHERE cultivation_variety='pisum_sativum_astronaute'"
    # Reverse: Merge item varieties#pisum_hibernum into pisum_sativum
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in product_natures#derivative_of
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in product_natures#variety
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in product_nature_variants#derivative_of
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in product_nature_variants#variety
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in products#derivative_of
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in products#variety
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in activities#support_variety
    # Cannot unmerge 'pisum_hibernum' from 'pisum_sativum' in activities#cultivation_variety
    # Reverse: Merge item varieties#pisum_vernum into pisum_sativum
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in product_natures#derivative_of
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in product_natures#variety
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in product_nature_variants#derivative_of
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in product_nature_variants#variety
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in products#derivative_of
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in products#variety
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in activities#support_variety
    # Cannot unmerge 'pisum_vernum' from 'pisum_sativum' in activities#cultivation_variety
    # Reverse: Change item varieties#medicago_comete with {:name=>"medicago_sativa_comete", :parent=>"medicago_sativa"}
    execute "UPDATE product_natures SET derivative_of='medicago_comete' WHERE derivative_of='medicago_sativa_comete'"
    execute "UPDATE product_natures SET variety='medicago_comete' WHERE variety='medicago_sativa_comete'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='medicago_comete' WHERE cultivation_variety='medicago_sativa_comete'"
    execute "UPDATE product_nature_variants SET derivative_of='medicago_comete' WHERE derivative_of='medicago_sativa_comete'"
    execute "UPDATE product_nature_variants SET variety='medicago_comete' WHERE variety='medicago_sativa_comete'"
    execute "UPDATE products SET derivative_of='medicago_comete' WHERE derivative_of='medicago_sativa_comete'"
    execute "UPDATE products SET variety='medicago_comete' WHERE variety='medicago_sativa_comete'"
    execute "UPDATE activities SET support_variety='medicago_comete' WHERE support_variety='medicago_sativa_comete'"
    execute "UPDATE activities SET cultivation_variety='medicago_comete' WHERE cultivation_variety='medicago_sativa_comete'"
    # Reverse: Change item varieties#citrullus_lanatus_gigérine with {:name=>"citrullus_lanatus_gigerine"}
    execute "UPDATE product_natures SET derivative_of='citrullus_lanatus_gigérine' WHERE derivative_of='citrullus_lanatus_gigerine'"
    execute "UPDATE product_natures SET variety='citrullus_lanatus_gigérine' WHERE variety='citrullus_lanatus_gigerine'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='citrullus_lanatus_gigérine' WHERE cultivation_variety='citrullus_lanatus_gigerine'"
    execute "UPDATE product_nature_variants SET derivative_of='citrullus_lanatus_gigérine' WHERE derivative_of='citrullus_lanatus_gigerine'"
    execute "UPDATE product_nature_variants SET variety='citrullus_lanatus_gigérine' WHERE variety='citrullus_lanatus_gigerine'"
    execute "UPDATE products SET derivative_of='citrullus_lanatus_gigérine' WHERE derivative_of='citrullus_lanatus_gigerine'"
    execute "UPDATE products SET variety='citrullus_lanatus_gigérine' WHERE variety='citrullus_lanatus_gigerine'"
    execute "UPDATE activities SET support_variety='citrullus_lanatus_gigérine' WHERE support_variety='citrullus_lanatus_gigerine'"
    execute "UPDATE activities SET cultivation_variety='citrullus_lanatus_gigérine' WHERE cultivation_variety='citrullus_lanatus_gigerine'"
    # Reverse: Change item varieties#avena_une_de_mai with {:name=>"avena_sativa_une_de_mai", :parent=>"avena_sativa"}
    execute "UPDATE product_natures SET derivative_of='avena_une_de_mai' WHERE derivative_of='avena_sativa_une_de_mai'"
    execute "UPDATE product_natures SET variety='avena_une_de_mai' WHERE variety='avena_sativa_une_de_mai'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='avena_une_de_mai' WHERE cultivation_variety='avena_sativa_une_de_mai'"
    execute "UPDATE product_nature_variants SET derivative_of='avena_une_de_mai' WHERE derivative_of='avena_sativa_une_de_mai'"
    execute "UPDATE product_nature_variants SET variety='avena_une_de_mai' WHERE variety='avena_sativa_une_de_mai'"
    execute "UPDATE products SET derivative_of='avena_une_de_mai' WHERE derivative_of='avena_sativa_une_de_mai'"
    execute "UPDATE products SET variety='avena_une_de_mai' WHERE variety='avena_sativa_une_de_mai'"
    execute "UPDATE activities SET support_variety='avena_une_de_mai' WHERE support_variety='avena_sativa_une_de_mai'"
    execute "UPDATE activities SET cultivation_variety='avena_une_de_mai' WHERE cultivation_variety='avena_sativa_une_de_mai'"
    # Reverse: Change item varieties#avena_evora with {:name=>"avena_sativa_evora", :parent=>"avena_sativa"}
    execute "UPDATE product_natures SET derivative_of='avena_evora' WHERE derivative_of='avena_sativa_evora'"
    execute "UPDATE product_natures SET variety='avena_evora' WHERE variety='avena_sativa_evora'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='avena_evora' WHERE cultivation_variety='avena_sativa_evora'"
    execute "UPDATE product_nature_variants SET derivative_of='avena_evora' WHERE derivative_of='avena_sativa_evora'"
    execute "UPDATE product_nature_variants SET variety='avena_evora' WHERE variety='avena_sativa_evora'"
    execute "UPDATE products SET derivative_of='avena_evora' WHERE derivative_of='avena_sativa_evora'"
    execute "UPDATE products SET variety='avena_evora' WHERE variety='avena_sativa_evora'"
    execute "UPDATE activities SET support_variety='avena_evora' WHERE support_variety='avena_sativa_evora'"
    execute "UPDATE activities SET cultivation_variety='avena_evora' WHERE cultivation_variety='avena_sativa_evora'"
  end
end
