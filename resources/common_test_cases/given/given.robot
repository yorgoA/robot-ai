*** Settings ***
Documentation    Composite Given (precondition) flows shared across test suites.
Resource         ../../keywords/given.resource
Resource         ../../keywords/when.resource
Resource         ../../keywords/then.resource


*** Keywords ***
A Logged-In User Session Is Started
    [Documentation]    Opens the browser, navigates to login, and authenticates as a valid user.
    Open Browser To App
    I Am On The Login Page
    I Submit Valid Credentials
    I Should Be Logged In

A Logged-In User Session Is Started With Empty Cart
    [Documentation]    Logs in via browser and clears the cart via API so tests start from a known state.
    I Am Authenticated To The API
    I Clear My Cart Via API
    A Logged-In User Session Is Started

I Have Items In My Cart
    [Documentation]    Starts a logged-in session and adds the first product to the cart.
    A Logged-In User Session Is Started
    I Am On The Product Catalog
    I Add The First Product To My Cart
