export const TABLES = {
  VENDORS: 'vendors',
  CUSTOMERS: 'customers',
  INVOICES: 'invoices',
  INVOICE_ITEMS: 'invoice_items',
  DELIVERIES: 'deliveries',
  DELIVERY_ITEMS: 'delivery_items',
  CUSTOMER_DEFAULT_ITEMS: 'customer_default_items',
  MILK_PRICING: 'milk_pricing',
};

export enum PAYMENT_STATUS {
  PAID = 'paid',
  UNPAID = 'unpaid',
  PENDING = 'pending',
  CANCELLED = 'cancelled',
}

export const ROUTES = {
  // Vendors
  VENDORS: '/api/vendors',
  VENDORS_ROOT: '/',
  VENDORS_ME: '/me',

  // Invoices
  INVOICES: '/api/invoices',
  INVOICES_ROOT: '/',
  INVOICES_BY_ID: '/:id',
  INVOICES_MARK_PAID: '/:id/pay',

  // Base
  ROOT: '/',
}

export const ERROR_CODES = {
  SUCCESS: 200,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  NOT_FOUND: 404,
  SERVER_ERROR: 500,
}

export const MESSAGES = {
  // General
  UNAUTHORIZED: 'Unauthorized',
  FETCH_FAILED: 'Failed to fetch data',
  UPDATE_FAILED: 'Failed to update record',
  API_RUNNING: "API is running!",
  SERVER_RUNNING: "Server is running on port:",

  // Auth
  MISSING_AUTH_HEADER: 'Missing or invalid authorization header',
  NO_USER_DATA: 'No user data found',
  AUTH_CHECK_FAILED: 'Authentication check failed',

  // Vendors
  VENDOR_NOT_FOUND: 'Vendor not found',
  FETCH_FAILED_VENDOR: 'Failed to fetch vendor',
  FETCH_FAILED_VENDORS: 'Failed to fetch vendors',

  // Invoices
  INVOICE_NOT_FOUND: 'Invoice not found',
  MISSING_INVOICE_ID: 'Missing invoice ID',
  FETCH_FAILED_INVOICE: 'Failed to fetch invoice',
  FETCH_FAILED_INVOICES: 'Failed to fetch invoices',
  UPDATE_FAILED_PAYMENT: 'Failed to update invoice payment status',
}





