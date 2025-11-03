import { supabase } from '../utils/supabaseClient'
import { TABLES } from '../constants'

export async function getAllVendors() {
  const { data, error } = await supabase
    .from(TABLES.VENDORS)
    .select('*')

  if (error) throw new Error(error.message)
  return data
}

export async function getVendorById(id: string) {
  const { data, error } = await supabase
    .from(TABLES.VENDORS)
    .select('*')
    .eq('id', id)
    .single()

  if (error) throw new Error(error.message)
  return data
}