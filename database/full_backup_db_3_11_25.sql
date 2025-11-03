


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."generate_invoice"("p_vendor_id" "uuid", "p_customer_id" "uuid", "p_month" character, "p_discount" numeric DEFAULT 0.00) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_invoice_id uuid;
BEGIN
  -- 1️⃣ Insert monthly invoice summary
  INSERT INTO invoices (
    vendor_id, customer_id, month,
    total_litres, total_milk_amount, total_delivery_charges,
    discount_amount, final_amount
  )
  SELECT
    p_vendor_id,
    p_customer_id,
    p_month,
    COALESCE(SUM(di.quantity_litres), 0)::numeric(10,2),
    COALESCE(SUM(di.total_amount), 0)::numeric(12,2),
    COALESCE(SUM(d.delivery_charge), 0)::numeric(12,2),
    p_discount::numeric(12,2),
    (COALESCE(SUM(di.total_amount), 0) + COALESCE(SUM(d.delivery_charge), 0) - p_discount)::numeric(12,2)
  FROM deliveries d
  JOIN delivery_items di ON di.delivery_id = d.id
  WHERE d.customer_id = p_customer_id
    AND to_char(d.date, 'YYYY-MM') = p_month
  GROUP BY p_vendor_id, p_customer_id, p_month
  RETURNING id INTO v_invoice_id;

  -- 2️⃣ Add invoice items (grouped)
  INSERT INTO invoice_items (
    invoice_id, brand_name, packet_size_litre, rate_per_packet,
    total_packets, total_litres, amount
  )
  SELECT
    v_invoice_id,
    mp.brand_name,
    di.packet_size_litre,
    di.price_per_packet,
    SUM(di.quantity_packets)::numeric(8,2),
    SUM(di.quantity_litres)::numeric(10,2),
    SUM(di.total_amount)::numeric(12,2)
  FROM deliveries d
  JOIN delivery_items di ON di.delivery_id = d.id
  JOIN milk_pricing mp ON mp.id = di.milk_pricing_id
  WHERE d.customer_id = p_customer_id
    AND to_char(d.date, 'YYYY-MM') = p_month
  GROUP BY mp.brand_name, di.packet_size_litre, di.price_per_packet;

  RETURN v_invoice_id;
END;
$$;


ALTER FUNCTION "public"."generate_invoice"("p_vendor_id" "uuid", "p_customer_id" "uuid", "p_month" character, "p_discount" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_vendor_on_delivery"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.vendor_id := (SELECT vendor_id FROM customers WHERE id = NEW.customer_id);
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_vendor_on_delivery"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."customer_default_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "customer_id" "uuid",
    "milk_pricing_id" "uuid",
    "default_quantity_packets" numeric(6,2) DEFAULT 1.0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."customer_default_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."customers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vendor_id" "uuid",
    "name" "text" NOT NULL,
    "phone" "text",
    "email" "text",
    "building_no" "text",
    "building_name" "text",
    "flat_no" "text",
    "wing" "text",
    "room_no" "text",
    "area" "text",
    "pincode" "text",
    "city" "text",
    "default_delivery_charge_per_day" numeric(8,2) DEFAULT 0.00,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."customers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."deliveries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vendor_id" "uuid",
    "customer_id" "uuid",
    "date" "date" NOT NULL,
    "delivery_charge" numeric(8,2) DEFAULT 0.00,
    "remarks" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."deliveries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."delivery_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "delivery_id" "uuid",
    "milk_pricing_id" "uuid",
    "packet_size_litre" numeric(3,2) NOT NULL,
    "price_per_packet" numeric(8,2) NOT NULL,
    "quantity_packets" numeric(6,2) NOT NULL,
    "quantity_litres" numeric(8,2) GENERATED ALWAYS AS (("packet_size_litre" * "quantity_packets")) STORED,
    "total_amount" numeric(10,2) GENERATED ALWAYS AS (("price_per_packet" * "quantity_packets")) STORED,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."delivery_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoice_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "invoice_id" "uuid",
    "brand_name" "text" NOT NULL,
    "packet_size_litre" numeric(3,2) NOT NULL,
    "rate_per_packet" numeric(8,2) NOT NULL,
    "total_packets" numeric(8,2) DEFAULT 0.00,
    "total_litres" numeric(10,2) DEFAULT 0.00,
    "amount" numeric(12,2) DEFAULT 0.00,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."invoice_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vendor_id" "uuid",
    "customer_id" "uuid",
    "month" character(7) NOT NULL,
    "total_litres" numeric(10,2) DEFAULT 0.00,
    "total_milk_amount" numeric(12,2) DEFAULT 0.00,
    "total_delivery_charges" numeric(12,2) DEFAULT 0.00,
    "discount_amount" numeric(12,2) DEFAULT 0.00,
    "final_amount" numeric(12,2) DEFAULT 0.00,
    "pdf_url" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "generated_at" timestamp with time zone DEFAULT "now"(),
    "is_paid" boolean DEFAULT false,
    "paid_at" timestamp with time zone
);


ALTER TABLE "public"."invoices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."milk_pricing" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vendor_id" "uuid",
    "brand_name" "text" NOT NULL,
    "packet_size_litre" numeric(3,2) NOT NULL,
    "price_per_packet" numeric(8,2) NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."milk_pricing" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vendors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "phone" "text",
    "email" "text",
    "shop_name" "text",
    "shop_address" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."vendors" OWNER TO "postgres";


ALTER TABLE ONLY "public"."customer_default_items"
    ADD CONSTRAINT "customer_default_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."deliveries"
    ADD CONSTRAINT "deliveries_customer_id_date_key" UNIQUE ("customer_id", "date");



ALTER TABLE ONLY "public"."deliveries"
    ADD CONSTRAINT "deliveries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."delivery_items"
    ADD CONSTRAINT "delivery_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoice_items"
    ADD CONSTRAINT "invoice_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_customer_id_month_key" UNIQUE ("customer_id", "month");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."milk_pricing"
    ADD CONSTRAINT "milk_pricing_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."milk_pricing"
    ADD CONSTRAINT "milk_pricing_vendor_id_brand_name_packet_size_litre_key" UNIQUE ("vendor_id", "brand_name", "packet_size_litre");



ALTER TABLE ONLY "public"."customer_default_items"
    ADD CONSTRAINT "unique_customer_milk" UNIQUE ("customer_id", "milk_pricing_id");



ALTER TABLE ONLY "public"."vendors"
    ADD CONSTRAINT "vendors_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_deliveries_vendor_date" ON "public"."deliveries" USING "btree" ("vendor_id", "date");



CREATE INDEX "idx_delivery_items_delivery_id" ON "public"."delivery_items" USING "btree" ("delivery_id");



CREATE INDEX "idx_delivery_items_milk_pricing_id" ON "public"."delivery_items" USING "btree" ("milk_pricing_id");



CREATE INDEX "idx_invoices_vendor_month" ON "public"."invoices" USING "btree" ("vendor_id", "month");



CREATE OR REPLACE TRIGGER "trg_set_vendor" BEFORE INSERT OR UPDATE ON "public"."deliveries" FOR EACH ROW EXECUTE FUNCTION "public"."set_vendor_on_delivery"();



ALTER TABLE ONLY "public"."customer_default_items"
    ADD CONSTRAINT "customer_default_items_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."customer_default_items"
    ADD CONSTRAINT "customer_default_items_milk_pricing_id_fkey" FOREIGN KEY ("milk_pricing_id") REFERENCES "public"."milk_pricing"("id");



ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."deliveries"
    ADD CONSTRAINT "deliveries_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."deliveries"
    ADD CONSTRAINT "deliveries_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."delivery_items"
    ADD CONSTRAINT "delivery_items_delivery_id_fkey" FOREIGN KEY ("delivery_id") REFERENCES "public"."deliveries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."delivery_items"
    ADD CONSTRAINT "delivery_items_milk_pricing_id_fkey" FOREIGN KEY ("milk_pricing_id") REFERENCES "public"."milk_pricing"("id");



ALTER TABLE ONLY "public"."invoice_items"
    ADD CONSTRAINT "invoice_items_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoices"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."milk_pricing"
    ADD CONSTRAINT "milk_pricing_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE CASCADE;



ALTER TABLE "public"."customer_default_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "customer_defaults_vendor" ON "public"."customer_default_items" USING ((EXISTS ( SELECT 1
   FROM "public"."customers" "c"
  WHERE (("c"."id" = "customer_default_items"."customer_id") AND ("c"."vendor_id" = "auth"."uid"())))));



ALTER TABLE "public"."customers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "customers_self_select" ON "public"."customers" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "customers_vendor" ON "public"."customers" USING (("auth"."uid"() = "vendor_id"));



ALTER TABLE "public"."deliveries" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "deliveries_vendor" ON "public"."deliveries" USING (("auth"."uid"() = "vendor_id"));



ALTER TABLE "public"."delivery_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "delivery_items_vendor" ON "public"."delivery_items" USING ((EXISTS ( SELECT 1
   FROM "public"."deliveries" "d"
  WHERE (("d"."id" = "delivery_items"."delivery_id") AND ("d"."vendor_id" = "auth"."uid"())))));



ALTER TABLE "public"."invoice_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "invoice_items_vendor" ON "public"."invoice_items" USING ((EXISTS ( SELECT 1
   FROM "public"."invoices" "i"
  WHERE (("i"."id" = "invoice_items"."invoice_id") AND ("i"."vendor_id" = "auth"."uid"())))));



ALTER TABLE "public"."invoices" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "invoices_customer_select" ON "public"."invoices" FOR SELECT USING (("auth"."uid"() = "customer_id"));



CREATE POLICY "invoices_vendor" ON "public"."invoices" USING (("auth"."uid"() = "vendor_id"));



ALTER TABLE "public"."milk_pricing" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "milk_pricing_vendor" ON "public"."milk_pricing" USING (("auth"."uid"() = "vendor_id"));



ALTER TABLE "public"."vendors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vendors_is_owner" ON "public"."vendors" USING (("auth"."uid"() = "id"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."generate_invoice"("p_vendor_id" "uuid", "p_customer_id" "uuid", "p_month" character, "p_discount" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."generate_invoice"("p_vendor_id" "uuid", "p_customer_id" "uuid", "p_month" character, "p_discount" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_invoice"("p_vendor_id" "uuid", "p_customer_id" "uuid", "p_month" character, "p_discount" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_vendor_on_delivery"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_vendor_on_delivery"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_vendor_on_delivery"() TO "service_role";


















GRANT ALL ON TABLE "public"."customer_default_items" TO "anon";
GRANT ALL ON TABLE "public"."customer_default_items" TO "authenticated";
GRANT ALL ON TABLE "public"."customer_default_items" TO "service_role";



GRANT ALL ON TABLE "public"."customers" TO "anon";
GRANT ALL ON TABLE "public"."customers" TO "authenticated";
GRANT ALL ON TABLE "public"."customers" TO "service_role";



GRANT ALL ON TABLE "public"."deliveries" TO "anon";
GRANT ALL ON TABLE "public"."deliveries" TO "authenticated";
GRANT ALL ON TABLE "public"."deliveries" TO "service_role";



GRANT ALL ON TABLE "public"."delivery_items" TO "anon";
GRANT ALL ON TABLE "public"."delivery_items" TO "authenticated";
GRANT ALL ON TABLE "public"."delivery_items" TO "service_role";



GRANT ALL ON TABLE "public"."invoice_items" TO "anon";
GRANT ALL ON TABLE "public"."invoice_items" TO "authenticated";
GRANT ALL ON TABLE "public"."invoice_items" TO "service_role";



GRANT ALL ON TABLE "public"."invoices" TO "anon";
GRANT ALL ON TABLE "public"."invoices" TO "authenticated";
GRANT ALL ON TABLE "public"."invoices" TO "service_role";



GRANT ALL ON TABLE "public"."milk_pricing" TO "anon";
GRANT ALL ON TABLE "public"."milk_pricing" TO "authenticated";
GRANT ALL ON TABLE "public"."milk_pricing" TO "service_role";



GRANT ALL ON TABLE "public"."vendors" TO "anon";
GRANT ALL ON TABLE "public"."vendors" TO "authenticated";
GRANT ALL ON TABLE "public"."vendors" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































RESET ALL;
