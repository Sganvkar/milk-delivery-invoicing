import { supabase } from '../utils/supabaseClient'
import { TABLES, PAYMENT_STATUS } from '../constants'

export async function getInvoicesByVendorId(vendorId: string) {
  const { data, error } = await supabase
    .from(TABLES.INVOICES)
    .select('*')
    .eq('vendor_id', vendorId)
    .order('generated_at', { ascending: false })

  if (error) throw new Error(error.message)
  return data
}

export async function getInvoiceById(vendorId: string, invoiceId: string) {
  const { data, error } = await supabase
    .from(TABLES.INVOICES)
    .select(`
      id,
      vendor_id,
      customer_id,
      month,
      total_milk_amount,
      total_delivery_charges,
      discount_amount,
      final_amount,
      pdf_url,
      status,
      generated_at,
      customers(name),
      invoice_items(
        brand_name,
        packet_size_litre,
        rate_per_packet,
        total_packets,
        amount
      )
    `)
    .eq('vendor_id', vendorId)
    .eq('id', invoiceId)
    .single()

  if (error) throw new Error(error.message)
  return data
}

export async function markInvoiceAsPaid(vendorId: string, invoiceId: string) {
  const { data, error } = await supabase
    .from(TABLES.INVOICES)
    .update({
      is_paid: true,
      paid_at: new Date().toISOString(),
      status: PAYMENT_STATUS.PAID,
    })
    .eq('vendor_id', vendorId)
    .eq('id', invoiceId)
    .select('*')
    .single()

  if (error) throw new Error(error.message)
  return data
}
