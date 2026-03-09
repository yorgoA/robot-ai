*** Settings ***
Resource    ../../selectors/catalog.resource
Resource    ../variables.robot

*** Variables ***
# Catalog is the home page
${CATALOG_URL}      ${BASE_URL}/
${ORDERS_URL}       ${BASE_URL}/orders
${PROFILE_URL}      ${BASE_URL}/profile
