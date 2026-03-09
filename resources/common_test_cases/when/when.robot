*** Settings ***
Documentation    Composite When (action) flows shared across test suites.
Resource         ../../keywords/given.resource
Resource         ../../keywords/when.resource
Resource         ../../keywords/then.resource


*** Keywords ***
A Product Is Added To The Cart
    [Documentation]    Navigates to the catalog and adds the first product to the cart.
    I Am On The Product Catalog
    I Add The First Product To My Cart

The Full Checkout Flow Is Completed
    [Documentation]    Adds a product, navigates to cart, and places the order.
    A Product Is Added To The Cart
    I Navigate To My Cart
    My Cart Should Have Items
    I Click Checkout
