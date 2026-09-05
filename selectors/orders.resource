*** Variables ***
# Order-card selectors shared with the post-checkout confirmation (order-success,
# order-id, order-card, order-status, orders-list, download-receipt-button, and
# view-orders-button) already live in selectors/cart.resource - only the
# Orders-page-specific ones are added here.
${SEL_ORDER_DATE}                [data-testid="order-date"]
${SEL_ORDER_TOTAL}               [data-testid="order-total"]
${SEL_ORDER_ITEMS}               [data-testid="order-items"]
${SEL_ORDER_ITEM}                [data-testid="order-item"]
${SEL_EMPTY_ORDERS}              [data-testid="empty-orders"]
${SEL_BROWSE_PRODUCTS_BUTTON}    [data-testid="browse-products-button"]
