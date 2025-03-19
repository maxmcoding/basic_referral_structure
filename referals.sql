-- public.referrers definition

-- Drop table

-- DROP TABLE public.referrers;

CREATE TABLE public.referrers (
	referrer_id serial4 NOT NULL,
	referrer_code varchar(20) NOT NULL,
	commission_rate numeric(5, 2) DEFAULT 0.00 NOT NULL,
	total_commissions numeric(10, 2) DEFAULT 0.00 NOT NULL,
	total_referrals int4 DEFAULT 0 NOT NULL,
	active bool DEFAULT true NOT NULL,
	tier varchar(20) NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT referrers_pkey PRIMARY KEY (referrer_id),
	CONSTRAINT referrers_referrer_code_key UNIQUE (referrer_code),
	CONSTRAINT referrers_tier_check CHECK (((tier)::text = ANY ((ARRAY['basic'::character varying, 'silver'::character varying, 'gold'::character varying, 'platinum'::character varying])::text[])))
);

INSERT INTO public.referrers
(referrer_id, referrer_code, commission_rate, total_commissions, total_referrals, active, tier, created_at)
VALUES(0, 'DEFAULT', 0.00, 0.00, 0, true, NULL, '2025-01-01 00:00:00.697');

-- public.services definition

-- Drop table

-- DROP TABLE public.services;

CREATE TABLE public.services (
	service_id serial4 NOT NULL,
	service_name varchar(255) NOT NULL,
	base_price numeric(10, 2) NOT NULL,
	included_units int4 NOT NULL,
	overage_rate numeric(10, 2) NOT NULL,
	unit_name varchar(50) DEFAULT 'units'::character varying NOT NULL,
	CONSTRAINT services_pkey PRIMARY KEY (service_id)
);


-- public.coupons definition

-- Drop table

-- DROP TABLE public.coupons;

CREATE TABLE public.coupons (
	code varchar(20) NOT NULL,
	discount_type varchar(10) NOT NULL,
	discount_value numeric(10, 2) NOT NULL,
	expires_at date NULL,
	max_uses int4 NULL,
	referrer_id int4 NULL,
	times_used int4 DEFAULT 0 NULL,
	CONSTRAINT coupons_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['percentage'::character varying, 'fixed'::character varying])::text[]))),
	CONSTRAINT coupons_pkey PRIMARY KEY (code),
	CONSTRAINT coupons_referrer_fk FOREIGN KEY (referrer_id) REFERENCES public.referrers(referrer_id)
);


-- public.customers definition

-- Drop table

-- DROP TABLE public.customers;

-- public.customers definition

-- Drop table

-- DROP TABLE public.customers;

CREATE TABLE public.customers (
	customer_id serial4 NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	last_referrer int4 NULL,
	first_name varchar(50) NOT NULL,
	last_name varchar(50) NOT NULL,
	email varchar(100) NOT NULL,
	phone varchar(20) NULL,
	address text NULL,
	city varchar(50) NULL,
	state varchar(50) NULL,
	zip_code varchar(20) NULL,
	country varchar(50) NULL,
	CONSTRAINT customers_email_key UNIQUE (email),
	CONSTRAINT customers_phone_key UNIQUE (phone),
	CONSTRAINT customers_pkey PRIMARY KEY (customer_id)
);


-- public.customers foreign keys
ALTER TABLE public.customers ALTER COLUMN last_referrer SET DEFAULT 0;

ALTER TABLE customers ADD CONSTRAINT customers_referrer_fk FOREIGN KEY (last_referrer) REFERENCES public.referrers(referrer_id);


-- public.referral_commissions definition

-- Drop table

-- DROP TABLE public.referral_commissions;

CREATE TABLE public.referral_commissions (
	commission_id serial4 NOT NULL,
	coupon_code varchar(20) NULL,
	commission_type varchar(10) NOT NULL,
	commission_value numeric(10, 2) NOT NULL,
	service_id int4 NULL,
	valid_from date DEFAULT CURRENT_DATE NOT NULL,
	valid_to date NULL,
	min_units int4 NULL,
	CONSTRAINT referral_commissions_commission_type_check CHECK (((commission_type)::text = ANY ((ARRAY['percentage'::character varying, 'fixed'::character varying])::text[]))),
	CONSTRAINT referral_commissions_pkey PRIMARY KEY (commission_id),
	CONSTRAINT valid_dates CHECK (((valid_to IS NULL) OR (valid_to >= valid_from))),
	CONSTRAINT referral_commissions_coupon_code_fkey FOREIGN KEY (coupon_code) REFERENCES public.coupons(code),
	CONSTRAINT referral_commissions_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id)
);


-- public.referrals definition

-- Drop table

-- DROP TABLE public.referrals;

CREATE TABLE public.referrals (
	referral_id serial4 NOT NULL,
	referrer_id int4 NOT NULL,
	referred_id int4 NOT NULL,
	coupon_code varchar(20) NULL,
	referral_date date DEFAULT CURRENT_DATE NOT NULL,
	CONSTRAINT referrals_pkey PRIMARY KEY (referral_id),
	CONSTRAINT referrals_coupon_code_fkey FOREIGN KEY (coupon_code) REFERENCES public.coupons(code),
	CONSTRAINT referrals_customer_fk FOREIGN KEY (referred_id) REFERENCES public.customers(customer_id),
	CONSTRAINT referrals_referrer_fk FOREIGN KEY (referrer_id) REFERENCES public.referrers(referrer_id)
);


-- public.reservations definition

-- Drop table

-- DROP TABLE public.reservations;

CREATE TABLE public.reservations (
	reservation_id serial4 NOT NULL,
	service_id int4 NULL,
	customer_id int4 NOT NULL,
	coupon_code varchar(20) NULL,
	reserved_units int4 NOT NULL,
	start_date date NOT NULL,
	end_date date NOT NULL,
	calculated_price numeric(10, 2) NULL,
	CONSTRAINT reservations_pkey PRIMARY KEY (reservation_id),
	CONSTRAINT fk_reservations_customers FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id),
	CONSTRAINT reservations_coupon_code_fkey FOREIGN KEY (coupon_code) REFERENCES public.coupons(code),
	CONSTRAINT reservations_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(service_id)
);



-- DROP FUNCTION public.calculate_reservation_price();
CREATE OR REPLACE FUNCTION public.calculate_reservation_price()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    service_record services%ROWTYPE;
    coupon_record coupons%ROWTYPE;
    base_calc NUMERIC;
BEGIN
    -- Get service pricing info
    SELECT * INTO service_record
    FROM services WHERE service_id = NEW.service_id;

    -- Calculate base price
    base_calc := service_record.base_price +
        GREATEST(NEW.reserved_units - service_record.included_units, 0) *
        service_record.overage_rate;

    -- Apply coupon discount if exists
    IF NEW.coupon_code IS NOT NULL THEN
        SELECT * INTO coupon_record
        FROM coupons
        WHERE code = NEW.coupon_code
          AND (expires_at IS NULL OR expires_at >= CURRENT_DATE)
          AND (max_uses IS NULL OR times_used < max_uses);

        IF FOUND THEN
            -- Update coupon usage
            UPDATE coupons SET times_used = times_used + 1
            WHERE code = NEW.coupon_code;

            -- Apply discount
            CASE coupon_record.discount_type
                WHEN 'percentage' THEN
                    base_calc := base_calc * (1 - coupon_record.discount_value/100);
                WHEN 'fixed' THEN
                    base_calc := GREATEST(base_calc - coupon_record.discount_value, 0);
            END CASE;
        END IF;
    END IF;

    NEW.calculated_price := base_calc;
    RETURN NEW;
END;
$function$
;





-- reservations Table Triggers

create trigger price_calculation_trigger before
insert
    or
update
    on
    public.reservations for each row execute function calculate_reservation_price();
create trigger referral_commission_trigger after
insert
    on
    public.reservations for each row execute function calculate_referral_commission();





-- public.referral_payouts definition

-- Drop table

-- DROP TABLE public.referral_payouts;

CREATE TABLE public.referral_payouts (
	payout_id serial4 NOT NULL,
	referral_id int4 NOT NULL,
	commission_id int4 NOT NULL,
	amount numeric(10, 2) NOT NULL,
	status varchar(20) DEFAULT 'pending'::character varying NOT NULL,
	created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	paid_date timestamp NULL,
	CONSTRAINT referral_payouts_pkey PRIMARY KEY (payout_id),
	CONSTRAINT referral_payouts_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'paid'::character varying])::text[]))),
	CONSTRAINT referral_payouts_commission_id_fkey FOREIGN KEY (commission_id) REFERENCES public.referral_commissions(commission_id),
	CONSTRAINT referral_payouts_referral_id_fkey FOREIGN KEY (referral_id) REFERENCES public.referrals(referral_id)
);
