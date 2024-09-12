-- 1
CREATE OR REPLACE FUNCTION format_date(date date, separator varchar)
RETURNS text
LANGUAGE plpgsql
AS $$
begin
-- en plpgsql, l'opérateur de concaténation est ||
return to_char(date, 'DD' || separator || 'MM' || separator || 'YYYY');
END;
$$

select format_date('2023-02-01', '/');

-- 2
select format_date(o.date, '-') from "order" o ;

-- 3
CREATE OR REPLACE FUNCTION get_items_count()
RETURNS integer
LANGUAGE plpgsql
AS $$
declare
items_count integer;
time_now time = now();
begin
select count(id)
into items_count
from item;
raise notice '% articles à %', items_count, time_now;
return items_count;
END;
$$

select get_items_count();

-- 4
CREATE OR REPLACE FUNCTION count_items_to_order()
RETURNS integer
LANGUAGE plpgsql
AS $$
declare
items_count integer;
time_now time = now();
begin
select count(id) 
into items_count
from item
where stock < stock_alert;
raise notice '% articles à %', items_count, time_now;
return items_count;
END;
$$

select count_items_to_order();

-- 5
CREATE OR REPLACE FUNCTION best_supplier()
RETURNS integer
LANGUAGE plpgsql
AS $$
declare
best_supplier integer;
time_now time = now();
begin
select supplier_id
into best_supplier
from "order"
group by supplier_id
order by count(supplier_id) desc
limit 1;
raise notice 'Supplier ID: % at %', best_supplier, time_now;
return best_supplier;
END;
$$

select best_supplier();

-- 6
-- switch case
CREATE OR REPLACE FUNCTION satisfaction_string(satisfaction_index integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
satisfaction varchar;
begin
-- := fonctionne comme le =
satisfaction := case 
when satisfaction_index is null then 'Sans commentaire'
when satisfaction_index = 1 or satisfaction_index = 2 then 'Mauvais'
when satisfaction_index = 3 or satisfaction_index = 4 then 'Passable'
when satisfaction_index = 5 or satisfaction_index = 6 then 'Moyen'
when satisfaction_index = 7 or satisfaction_index = 8 then 'Bon'
when satisfaction_index = 9 or satisfaction_index = 10 then 'Excellent'
else 'valeur invalide'
END;
return satisfaction;
end;
$$

-- if 
CREATE OR REPLACE FUNCTION satisfaction_string(satisfaction_index integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
satisfaction varchar;
begin
if satisfaction_index is null then satisfaction = 'Sans commentaire';
elsif satisfaction_index = 1 or satisfaction_index = 2 then satisfaction = 'Mauvais';
elsif satisfaction_index = 3 or satisfaction_index = 4 then satisfaction = 'Passable';
elsif satisfaction_index = 5 or satisfaction_index = 6 then satisfaction = 'Moyen';
elsif satisfaction_index = 7 or satisfaction_index = 8 then satisfaction = 'Bon';
elsif satisfaction_index = 9 or satisfaction_index = 10 then satisfaction = 'Excellent';
else satisfaction = 'valeur invalide';
END if;
return satisfaction;
end;
$$

-- plus opti
CREATE OR REPLACE FUNCTION satisfaction_string(satisfaction_index integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
satisfaction varchar;
begin
if satisfaction_index is null then satisfaction = 'Sans commentaire';
elsif satisfaction_index < 3 then satisfaction = 'Mauvais';
elsif satisfaction_index < 5 then satisfaction = 'Passable';
elsif satisfaction_index < 7 then satisfaction = 'Moyen';
elsif satisfaction_index < 9 then satisfaction = 'Bon';
elsif satisfaction_index < 11 then satisfaction = 'Excellent';
else satisfaction = 'valeur invalide';
END if;
return satisfaction;
end;
$$

-- 7
select id, name, satisfaction_string(satisfaction_index) from supplier;

-- 8
CREATE OR REPLACE FUNCTION add_days(date date, days_to_add integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
new_date date;
begin
new_date := date + days_to_add;
return new_date;
end;
$$

select add_days('2023-10-10', 5);

create or replace
function get_items_count_by_supplier(s_id integer)
returns integer
language plpgsql
as $$
declare
items_count integer;

supplier_exists boolean;

begin
supplier_exists = exists(
select
	*
from
	supplier s
where
	s.id = s_id);

if supplier_exists = false then 
        raise exception 'L''identifiant % n''existe pas',
s_id
	using HINT = 
	'Vérifiez l''identifiant du fournisseur.';
end if;

select
	count(item_id)
into
	items_count
from
	sale_offer
where
	supplier_id = s_id;

return items_count;
end;

$$

select get_items_count_by_supplier(s.id) as items_count, s.name, s.id from supplier s ;



-- 9
CREATE OR REPLACE FUNCTION sales_revenue(s_id integer, year integer)
RETURNS float
LANGUAGE plpgsql
AS $$
declare
ca float;
taxe float = 1.2;
begin
select sum((ol.ordered_quantity*ol.unit_price)*taxe)
into ca
from order_line ol
join "order" o on o.id = ol.order_id
where o.supplier_id = s_id and extract(year from o.date) = year;
return ca;
end;
$$

select o.supplier_id, o.date, sales_revenue(o.supplier_id, 2021) from "order" o ;

-- 10
DROP FUNCTION get_items_stock_alert(); 
create or replace function get_items_stock_alert()  
    returns table ( 
        id int, 
        item_code character(4), 
        name varchar,
        stock_difference integer
    )  
    language plpgsql 
as $$ 
begin 
    return query  
        select 
		i.id,
		i.item_code,
		i.name,
		(i.stock_alert - i.stock) 
        from 
            item i 
        where 
		i.stock < i.stock_alert;
end;$$

select * from get_items_stock_alert();




create table public.user(
id serial primary key,
email varchar(50) not null,
last_connection timestamp, 
"password" varchar(50) not null,
"role" varchar(50) not null
)

CREATE OR REPLACE PROCEDURE insert_user(email varchar, password varchar, role varchar)
LANGUAGE plpgsql
AS $$
begin
if email not like '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' then raise exception 'Format incorrect!';
elsif (length(password) < 8) then raise exception '8 caractères minimum!';
elsif role not in('MAIN_ADMIN', 'ADMIN', 'COMMON')  then raise exception 'rôles acceptables « MAIN_ADMIN », « ADMIN », « COMMON »';
else 
INSERT INTO public.user(email, password, role) values (email, password, role);
end if;
end;
$$

call insert_user('marchiveflorian@gmail.com', 'motdepasse', 'ADMIN');




-- 1
CREATE OR REPLACE FUNCTION format_date(date date, separator varchar)
RETURNS text
LANGUAGE plpgsql
AS $$
begin
-- en plpgsql, l'opérateur de concaténation est ||
return to_char(date, 'DD' || separator || 'MM' || separator || 'YYYY');
END;
$$

select format_date('2023-02-01', '/');

-- 2
select format_date(o.date, '-') from "order" o ;

-- 3
CREATE OR REPLACE FUNCTION get_items_count()
RETURNS integer
LANGUAGE plpgsql
AS $$
declare
items_count integer;
time_now time = now();
begin
select count(id)
into items_count
from item;
raise notice '% articles à %', items_count, time_now;
return items_count;
END;
$$

select get_items_count();

-- 4
CREATE OR REPLACE FUNCTION count_items_to_order()
RETURNS integer
LANGUAGE plpgsql
AS $$
declare
items_count integer;
time_now time = now();
begin
select count(id) 
into items_count
from item
where stock < stock_alert;
raise notice '% articles à %', items_count, time_now;
return items_count;
END;
$$

select count_items_to_order();

-- 5
CREATE OR REPLACE FUNCTION best_supplier()
RETURNS integer
LANGUAGE plpgsql
AS $$
declare
best_supplier integer;
time_now time = now();
begin
select supplier_id
into best_supplier
from "order"
group by supplier_id
order by count(supplier_id) desc
limit 1;
raise notice 'Supplier ID: % at %', best_supplier, time_now;
return best_supplier;
END;
$$

select best_supplier();

-- 6
-- switch case
CREATE OR REPLACE FUNCTION satisfaction_string(satisfaction_index integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
satisfaction varchar;
begin
-- := fonctionne comme le =
satisfaction := case 
when satisfaction_index is null then 'Sans commentaire'
when satisfaction_index = 1 or satisfaction_index = 2 then 'Mauvais'
when satisfaction_index = 3 or satisfaction_index = 4 then 'Passable'
when satisfaction_index = 5 or satisfaction_index = 6 then 'Moyen'
when satisfaction_index = 7 or satisfaction_index = 8 then 'Bon'
when satisfaction_index = 9 or satisfaction_index = 10 then 'Excellent'
else 'valeur invalide'
END;
return satisfaction;
end;
$$

-- if 
CREATE OR REPLACE FUNCTION satisfaction_string(satisfaction_index integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
satisfaction varchar;
begin
if satisfaction_index is null then satisfaction = 'Sans commentaire';
elsif satisfaction_index = 1 or satisfaction_index = 2 then satisfaction = 'Mauvais';
elsif satisfaction_index = 3 or satisfaction_index = 4 then satisfaction = 'Passable';
elsif satisfaction_index = 5 or satisfaction_index = 6 then satisfaction = 'Moyen';
elsif satisfaction_index = 7 or satisfaction_index = 8 then satisfaction = 'Bon';
elsif satisfaction_index = 9 or satisfaction_index = 10 then satisfaction = 'Excellent';
else satisfaction = 'valeur invalide';
END if;
return satisfaction;
end;
$$

-- plus opti
CREATE OR REPLACE FUNCTION satisfaction_string(satisfaction_index integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
satisfaction varchar;
begin
if satisfaction_index is null then satisfaction = 'Sans commentaire';
elsif satisfaction_index < 3 then satisfaction = 'Mauvais';
elsif satisfaction_index < 5 then satisfaction = 'Passable';
elsif satisfaction_index < 7 then satisfaction = 'Moyen';
elsif satisfaction_index < 9 then satisfaction = 'Bon';
elsif satisfaction_index < 11 then satisfaction = 'Excellent';
else satisfaction = 'valeur invalide';
END if;
return satisfaction;
end;
$$

-- 7
select id, name, satisfaction_string(satisfaction_index) from supplier;

-- 8
CREATE OR REPLACE FUNCTION add_days(date date, days_to_add integer)
RETURNS varchar
LANGUAGE plpgsql
AS $$
declare
new_date date;
begin
new_date := date + days_to_add;
return new_date;
end;
$$

select add_days('2023-10-10', 5);

create or replace
function get_items_count_by_supplier(s_id integer)
returns integer
language plpgsql
as $$
declare
items_count integer;

supplier_exists boolean;

begin
supplier_exists = exists(
select
	*
from
	supplier s
where
	s.id = s_id);

if supplier_exists = false then 
        raise exception 'L''identifiant % n''existe pas',
s_id
	using HINT = 
	'Vérifiez l''identifiant du fournisseur.';
end if;

select
	count(item_id)
into
	items_count
from
	sale_offer
where
	supplier_id = s_id;

return items_count;
end;

$$

select get_items_count_by_supplier(s.id) as items_count, s.name, s.id from supplier s ;



-- 9
CREATE OR REPLACE FUNCTION sales_revenue(s_id integer, year integer)
RETURNS float
LANGUAGE plpgsql
AS $$
declare
ca float;
taxe float = 1.2;
begin
select sum((ol.ordered_quantity*ol.unit_price)*taxe)
into ca
from order_line ol
join "order" o on o.id = ol.order_id
where o.supplier_id = s_id and extract(year from o.date) = year;
return ca;
end;
$$

select o.supplier_id, o.date, sales_revenue(o.supplier_id, 2021) from "order" o ;

-- 10
DROP FUNCTION get_items_stock_alert(); 
create or replace function get_items_stock_alert()  
    returns table ( 
        id int, 
        item_code character(4), 
        name varchar,
        stock_difference integer
    )  
    language plpgsql 
as $$ 
begin 
    return query  
        select 
		i.id,
		i.item_code,
		i.name,
		(i.stock_alert - i.stock) 
        from 
            item i 
        where 
		i.stock < i.stock_alert;
end;$$

select * from get_items_stock_alert();




create table public.user(
id serial primary key,
email varchar(50) not null,
last_connection timestamp, 
"password" varchar(50) not null,
"role" varchar(50) not null
)

CREATE OR REPLACE PROCEDURE insert_user(email varchar, password varchar, role varchar)
LANGUAGE plpgsql
AS $$
begin
if email similar to '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' then raise exception 'Format incorrect!';
elsif (length(password) < 8) then raise exception '8 caractères minimum!';
elsif role not in('MAIN_ADMIN', 'ADMIN', 'COMMON')  then raise exception 'rôles acceptables « MAIN_ADMIN », « ADMIN », « COMMON »';
else 
INSERT INTO public.user(email, password, role) values (email, password, role);
end if;
end;
$$

call insert_user('marchiveflorian@gmail.com', 'motdepasse', 'ADMIN');




CREATE OR REPLACE function user_connection(user_email text, user_password text) 
 RETURNS boolean 
 LANGUAGE plpgsql 
as  $function$ 
declare  
    user_id_reference int; -- l'identifiant de l'utilisateur récupéré en base de données 
    user_password_reference text; -- le mot de passe de l'utilisateur récupéré en base de données 
    user_exists boolean; -- un indicateur d'existence de l'utilisateur 
    hashed_password text; -- va contenir le mot de passe haché 
	connexion_attempts int; -- nombre de tentatives de connexion 
	is_account_blocked boolean; -- indicateur si le compte est bloqué ou non
begin 
 
    -- vérification de l'existence de l'utilisateur 
    user_exists = exists(select * 
                        from "user" u 
                        where u.email like user_email); 
 
    -- si l'utilisateur existe, on vérifie d'abord si le compte est bloqué
    if user_exists then 
		select connexion_attempt, blocked_account
		into connexion_attempts, is_account_blocked
		from "user" u
		where u.email = user_email;
		
		-- si le compte est déjà bloqué, on retourne false
		if is_account_blocked then
			raise notice 'Le compte de l`utilisateur % est bloqué.', user_email;
			return false;
		end if;
			
        -- récupération du mot de passe stocké en BDD 
        select "password"  
        into user_password_reference 
        from "user" u 
        where u.email like user_email; 
     
        -- calcul du hash du mot de passe passé en paramètre et vérification avec le hash en BDD 
        hashed_password = encode(digest(user_password, 'sha1'), 'hex'); 
        if hashed_password like user_password_reference then 
			-- Mise à jour de la date et de l'heure de connexion + réinitialisation du compteur de connexion
			update "user"
			set last_connection = now(), connexion_attempt = 0
			where email = user_email;
            return true; 

		else 
			-- incrémentation du compteur de connexion
			update "user"
			set connexion_attempt = connexion_attempt + 1
			where email = user_email;
			
			-- vérification du nombre de connexion
			if connexion_attempts + 1 >= 3 then
			update "user"
			set blocked_account = true
			where email = user_email;
			
			raise notice 'Le compte de l`utilisateur % a été bloqué après 3 tentatives échouées.', user_email;
			else
			raise notice 'Mot de passe incorrect. Tentative % sur 3.', connexion_attempts +1;
			end if;
			return false;	
        end if; 
    end if; 
 
    -- alert pour l'utilisateur 
    raise notice 'L''utilisateur ayant pour email % n''existe pas en base de données.', 
user_email; 
    return false; 
END 
$function$; 



-- TRIGGERS
CREATE OR REPLACE FUNCTION display_message_on_supplier_insert() 
 RETURNS trigger 
 LANGUAGE plpgsql 
AS $$ 
BEGIN 
  raise notice '« Un ajout de fournisseur va être fait. Le nouveau fournisseur est %', NEW.name; 
  return NEW; 
END; 
$$

create trigger before_insert_supplier -- "before_insert_supplier" est le nom du déclencheur 
before insert -- indication sur le type d'évènement du déclencheur 
on public.supplier -- nom de la table concernée 
for each row -- quand se déclencher ? ROW ou statement (explication ci-dessous) 
execute function display_message_on_supplier_insert(); -- appel de la fonction lorsque le déclencheur s'active 



-- version update 
CREATE OR REPLACE FUNCTION display_message_on_supplier_update() 
 RETURNS trigger 
 LANGUAGE plpgsql 
AS $$ 
BEGIN 
  raise notice '« Mise à jour de la table des fournisseurs. % deviens %.', OLD.name, NEW.name; 
  return NEW; 
END; 
$$

create or replace trigger after_update_supplier -- "after_update_supplier" est le nom du déclencheur 
after update -- indication sur le type d'évènement du déclencheur 
on public.supplier -- nom de la table concernée 
for each row -- quand se déclencher ? ROW ou statement (explication ci-dessous) 
execute function display_message_on_supplier_update(); -- appel de la fonction lorsque le déclencheur s'active 
 
-- version delete 
CREATE OR REPLACE function check_user_delete() 
 RETURNS trigger 
 LANGUAGE plpgsql 
AS $function$ 
begin 
    if old.role = 'MAIN_ADMIN' then 
        raise exception 'Impossible de supprimer l`''utilisateur %. Il s''agit de 
l''administrateur principal.', old.id; 
    end if; 
  return null; 
END; 
$function$

create or replace trigger before_delete
before delete 
on public.user 
for each row 
execute function check_user_delete();

-- delete pour order_line
CREATE OR REPLACE function check_orderline_delete() 
 RETURNS trigger 
 LANGUAGE plpgsql 
AS $function$ 
begin 
    if (old.delivered_quantity < old.ordered_quantity) then 
        raise exception 'Impossible de supprimer car la commande % est en cours de livraison.', old.order_id; 
    end if; 
  return null; 
END; 
$function$

create or replace trigger check_orderline_delete
before delete 
on public.order_line 
for each row 
execute function check_orderline_delete();


delete from order_line where delivered_quantity < ordered_quantity;


-- items_to_order 
create table public.items_to_order (
id serial primary key, 
item_id integer, 
quantity integer, 
date_update date, 
foreign key (item_id) references item(id)
);

CREATE OR REPLACE function update_items_to_order() 
 RETURNS trigger 
 LANGUAGE plpgsql 
AS $function$ 
begin 
	-- Etape 4
	if NEW.stock < 0 then
	raise exception 'Le stock % ne peut pas passer négatif !', NEW.stock;
	return null;
	end if;
	if NEW.stock < NEW.stock_alert then
    insert into items_to_order (item_id, quantity, date_update)
	values (NEW.id, NEW.stock, now());
	raise notice 'l`article % avec le stock insuffisant à été rajouté à la table items_to_order.', NEW.id;
	end if;
  return NEW; 
END; 
$function$

create or replace trigger before_item_update
after update 
on public.item 
for each row 
execute function update_items_to_order();

update item 
set stock = 19
where id = 0;

-- 14
CREATE TABLE item_audit (
    audit_id SERIAL PRIMARY KEY,          -- Identifiant unique de l'enregistrement d'audit
    item_id INT NOT NULL,                 -- Identifiant de l'élément modifié dans la table 'item'
    operation_type VARCHAR(10),           -- Type d'opération (INSERT, UPDATE, DELETE)
    operation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Horodatage de l'opération
    executed_by VARCHAR(100)              -- Utilisateur ayant effectué l'opération
);

CREATE OR REPLACE FUNCTION audit_item_changes() 
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        -- Enregistrement d'une opération INSERT
        INSERT INTO item_audit(item_id, operation_type, executed_by)
        VALUES (NEW.id, TG_OP, SESSION_USER);
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        -- Enregistrement d'une opération UPDATE
        INSERT INTO item_audit(item_id, operation_type, executed_by)
        VALUES (OLD.id, TG_OP, SESSION_USER);
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        -- Enregistrement d'une opération DELETE
        INSERT INTO item_audit(item_id, operation_type, executed_by)
        VALUES (OLD.id, TG_OP, SESSION_USER);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour INSERT, UPDATE et DELETE
CREATE TRIGGER audit_item_changes_trigger
AFTER INSERT OR UPDATE OR DELETE ON item
FOR EACH ROW
EXECUTE FUNCTION audit_item_changes();

UPDATE public.item
set stock = 55
where id = 0;