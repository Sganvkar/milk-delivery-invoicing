import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { PDFDocument, StandardFonts, rgb } from "https://esm.sh/pdf-lib";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.46.0";
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
const bucket = "invoices";
serve(async (req)=>{
  try {
    const { invoice_id } = await req.json();
    const { data: invoice } = await supabase.from("invoices").select(`id,vendor_id,customer_id,month,total_litres,total_milk_amount,
         total_delivery_charges,discount_amount,final_amount,
         customers(name),vendors(shop_name)`).eq("id", invoice_id).single();
    const { data: items } = await supabase.from("invoice_items").select("brand_name,packet_size_litre,rate_per_packet,total_packets,amount").eq("invoice_id", invoice_id);
    // 🧾 Build PDF entirely in memory
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage([
      595.28,
      841.89
    ]); // A4
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const { width, height } = page.getSize();
    let y = height - 80;
    page.drawText(invoice.vendors.shop_name, {
      x: 200,
      y,
      size: 18,
      font
    });
    y -= 30;
    page.drawText(`Customer: ${invoice.customers.name}`, {
      x: 50,
      y,
      size: 12,
      font
    });
    y -= 20;
    page.drawText(`Month: ${invoice.month}`, {
      x: 50,
      y,
      size: 12,
      font
    });
    y -= 30;
    page.drawText("Items:", {
      x: 50,
      y,
      size: 12,
      font
    });
    y -= 20;
    items.forEach((i)=>{
      page.drawText(`${i.brand_name} ${i.packet_size_litre}L ×${i.total_packets} @Rs. ${i.rate_per_packet} = Rs. ${i.amount}`, {
        x: 60,
        y,
        size: 11,
        font
      });
      y -= 15;
    });
    y -= 20;
    page.drawText(`Delivery Charges: Rs. ${invoice.total_delivery_charges}`, {
      x: 50,
      y,
      size: 12,
      font
    });
    y -= 15;
    page.drawText(`Discount: Rs. ${invoice.discount_amount}`, {
      x: 50,
      y,
      size: 12,
      font
    });
    y -= 25;
    page.drawText(`Total Payable: Rs. ${invoice.final_amount}`, {
      x: 50,
      y,
      size: 14,
      font,
      color: rgb(0, 0, 0)
    });
    const pdfBytes = await pdfDoc.save();
    const filePath = `vendor_${invoice.vendor_id}/${invoice.month}/customer_${invoice.customer_id}.pdf`;
    const { error: uploadErr } = await supabase.storage.from(bucket).upload(filePath, new Uint8Array(pdfBytes), {
      contentType: "application/pdf",
      upsert: true
    });
    if (uploadErr) throw uploadErr;
    await supabase.from("invoices").update({
      pdf_url: filePath
    }).eq("id", invoice_id);
    return new Response(JSON.stringify({
      success: true,
      file_path: filePath
    }), {
      headers: {
        "Content-Type": "application/json"
      }
    });
  } catch (err) {
    console.error("❌ Error:", err);
    return new Response(JSON.stringify({
      success: false,
      error: err.message
    }), {
      status: 500,
      headers: {
        "Content-Type": "application/json"
      }
    });
  }
});
