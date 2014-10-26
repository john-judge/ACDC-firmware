--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--								University of Hawaii at Manoa						         --
--						Instrumentation Development Lab / GARY S. VARNER				--
--   								Watanabe Hall Room 214								      --
--  								  2505 Correa Road										   --
--  								 Honolulu, HI 96822											--
--  								Lab: (808) 956-2920											--
--	 								Fax: (808) 956-2930										   --
--  						E-mail: idlab@phys.hawaii.edu									   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--edited by: eoberla																				--
--FEB 2010																							--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity USBread is
   port ( xIFCLK     	: in    std_logic;
          xUSB_DATA  	: in    std_logic_vector (15 downto 0);
          xFLAGA    		: in    std_logic;
			 xRESET    		: in    std_logic;
          xWBUSY    		: in    std_logic;
          xFIFOADR  		: out   std_logic_vector (1 downto 0);
          xRBUSY    		: out   std_logic;
          xSLOE     		: out   std_logic;
          xSLRD     		: out   std_logic;
          xSYNC_USB 		: out   std_logic;
          xSOFT_TRIG		: out   std_logic;
			 xPED_SCAN		: out   std_logic_vector (11 downto 0);
			 xDEBUG 		  	: out   std_logic_vector (15 downto 0);
          xTOGGLE   		: out   std_logic);
end USBread;

architecture BEHAVIORAL of USBread is
	type State_type is(st1_WAIT,
							st1_READ, st2_READ, st3_READ,st4_READ,
							st1_SAVE, st1_TARGET, ENDDELAY);
	signal state: State_type;
	signal dbuffer			: std_logic_vector (15 downto 0);
	signal Locmd			: std_logic_vector (15 downto 0);
	signal Hicmd			: std_logic_vector (15 downto 0);
	signal again			: std_logic_vector (1 downto 0);
	signal TOGGLE			: std_logic;
	signal SOFT_TRIG		: std_logic;
	signal DEBUG	    	: std_logic_vector (15 downto 0);
   signal PED_SCAN    	: std_logic_vector (11 downto 0);
	signal SYNC_USB		: std_logic;
	signal SLRD				: std_logic;
	signal SLOE				: std_logic;
	signal RBUSY			: std_logic;
	signal FIFOADR    	: std_logic_vector (1 downto 0);
	signal TX_LENGTH     : std_logic_vector (13 downto 0);
--------------------------------------------------------------------------------
begin
--------------------------------------------------------------------------------
	xTOGGLE 		<= TOGGLE;
	xSOFT_TRIG 	<= SOFT_TRIG;
	xDEBUG 		<= DEBUG;
	xPED_SCAN 	<= PED_SCAN;
	xSYNC_USB 	<= SYNC_USB;
	xSLRD 		<= SLRD;
	xSLOE 		<= SLOE;
	xRBUSY 		<= RBUSY;
	xFIFOADR 	<= FIFOADR;
--------------------------------------------------------------------------------
	process(xIFCLK, xRESET)
	variable delay : integer range 0 to 10;
	begin
		if xRESET = '0' then
			SYNC_USB		<= '0';
			SOFT_TRIG	<= '0';
			DEBUG			<= (others=>'0');
			PED_SCAN		<= (others=>'0');
			SLRD 			<= '1';
			SLOE 			<= '1';
			FIFOADR 		<= "10";
			TOGGLE 		<= '0';
			again 		<= "00";
			RBUSY 		<= '1';
			delay 		:= 0;	
			state       <= st1_WAIT;
		elsif rising_edge(xIFCLK) then
			SLOE 			<= '1';
			SLRD 			<= '1';			
			FIFOADR 		<= "10";
			TOGGLE 		<= '0';
			SOFT_TRIG	<= '0';
			RBUSY 		<= '1';
--------------------------------------------------------------------------------				
			case	state is	
--------------------------------------------------------------------------------
				when st1_WAIT =>
					RBUSY <= '0';						 
					if xFLAGA = '1' then	
						RBUSY <= '1';
						if xWBUSY = '0' then		
							RBUSY <= '1';
							state <= st1_READ;
						end if;
					end if;		 
--------------------------------------------------------------------------------		
				when st1_READ =>
					FIFOADR <= "00";	
					TOGGLE <= '1';		
					if delay = 2 then
						delay := 0;
						state <= st2_READ;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------					
				when st2_READ =>	
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						state <= st3_READ;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------						
				when st3_READ =>					
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					SLRD <= '0';
					dbuffer <= xUSB_DATA;
					if delay = 2 then
						delay := 0;
						state <= st4_READ;
					else
						delay := delay +1;
					end if;					
--------------------------------------------------------------------------------					   
				when st4_READ =>					
					FIFOADR <= "00";
					TOGGLE <= '1';
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						state <= st1_SAVE;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------	
				when st1_SAVE	=>
					FIFOADR <= "00";
					TOGGLE <= '1';	
--------------------------------------------------------------------------------						
					case again is 
						when "00" =>	
							again <="01";	
							Locmd <= dbuffer;
							state <= ENDDELAY;
--------------------------------------------------------------------------------	
						when "01" =>
							again <="00";	
							Hicmd <= dbuffer;	
							state <= st1_TARGET;
--------------------------------------------------------------------------------	
						when others =>				
							state <= st1_WAIT;
					end case;
--------------------------------------------------------------------------------	
				when st1_TARGET =>
					RBUSY <= '0';
					case Locmd(7 downto 0) is
--------------------------------------------------------------------------------
-----------       Software People only care about this part :-p    -------------
--------------------------------------------------------------------------------
						when x"01" =>	--USE SYNC signal
							SYNC_USB <= Hicmd(0); 
							state <= st1_WAIT;		--HICMD "XXXX-XXXX-XXXX-XXXD"
							
						when x"02" =>	--SOFT_TRIG
							SOFT_TRIG <= '1';	 		
							state <= st1_WAIT;		--HICMD =>"XXX-XXXX-XXXX-XXXX"
						
						when x"03" =>	--PED_SCAN
							PED_SCAN <=  Hicmd(11 downto 0);	
							state <= st1_WAIT;		--HICMD =>"XXX-DDDD-DDDD-DDDD"
							
						when x"FF" =>	--W_STRB
							DEBUG <= Hicmd(15 downto 0);
							state <= st1_WAIT;		--HICMD "DDDD-DDDD-DDDD-DDDD"
							
--------------------------------------------------------------------------------
-----------       Software People stop caring at this point  ^_^   -------------
--------------------------------------------------------------------------------
						when others =>
							state <= st1_WAIT;
					end case;
--------------------------------------------------------------------------------	
				when ENDDELAY =>	
					FIFOADR <= "00"; 
					if delay = 2 then
						if xFLAGA = '1' then
							delay := 0;
							state <= st1_READ;
						else
							delay := 0;
							state <= st1_WAIT;
						end if;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------						
				when others =>
					state <= st1_WAIT;
			end case;	  
		end if;
	end process;
--------------------------------------------------------------------------------	
end Behavioral;
