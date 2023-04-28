/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>

//#define reg_mprj_slave (*(volatile uint32_t*)0x30000000)
#define KEY      (*(volatile uint64_t*)0x30000000)
#define PLAIN   (*(volatile uint64_t*)0x300000008)
#define CMOS_OUT   (*(volatile uint64_t*)0x30000010)
#define CONTROL   (*(volatile uint64_t*)0x300000018)


/*
	Wishbone Test:
		- Configures MPRJ lower 8-IO pins as outputs
		- Checks counter value through the wishbone port
*/

void main()
{

	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |
	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |
	*/

	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

    reg_spi_enable = 1;
    reg_wb_enable = 1;
	reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

    // Connect the housekeeping SPI to the SPI master
    // so that the CSB line is not left floating.  This allows
    // all of the GPIO pins to be used for user functions.

    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

     /* Apply configuration */
    reg_mprj_xfer = 1; //I think this is implying setting transfer to be true
    while (reg_mprj_xfer == 1);

	//reg_la2_oenb = reg_la2_iena = 0x00000000;    // [95:64]

    // Flag start of the test
    	reg_mprg_datal = 0xAB600000;
    for (int i = 0; i < 4; i++){
        if (i==0){
            KEY = 0x0123456789ABCDEFL;
            if (KEY != 0x0123456789ABCDEFL){
            //reg_mprj_datal = 0xAB600000; //how they flagged the start of the test
            //break;  //no break? 
            }
            PLAIN = 0x0101010101010101L;
            if (KEY != 0x0101010101010101L){
            //reg_mprj_datal = 0xAB610000; 
            }
            CMOS_OUT = 0xFEDCBA9876543210L;
            if (KEY != 0xFEDCBA9876543210L){
            //reg_mprj_datal = 0xAB610000;
            }
        }
        else if (i==1){
            KEY = 0x0101010101010101L;
            if (KEY != 0x0101010101010101L){
            //reg_mprj_datal = 0xAB610000;
            }
            PLAIN = 0x0123456789ABCDEFL;
            if (KEY != 0x0123456789ABCDEFL){
            //reg_mprj_datal = 0xAB610000;
            }
            CMOS_OUT = 0x2222222222222222L;
            if (KEY != 0x2222222222222222L){
            //reg_mprj_datal = 0xAB610000;
            }
        }
        else if (i==2){
            KEY = 0xFEDCBA9876543210L;
            if (KEY != 0xFEDCBA9876543210L){
            //reg_mprj_datal = 0xAB610000;
            }
            PLAIN = 0x6969696969696969L;
            if (KEY != 0x6969696969696969L){
            //reg_mprj_datal = 0xAB610000;
            }
            CMOS_OUT = 0x0123456789ABCDEFL;
            if (KEY != 0x0123456789ABCDEFL){
            //reg_mprj_datal = 0xAB610000;
            }
        }
        else if (i==3){
            KEY = 0x6969696969696969L;
            if (KEY != 0x6969696969696969L){
            //reg_mprj_datal = 0xAB610000;
            }
            PLAIN = 0xFEDCBA9876543210L;
            if (KEY != 0xFEDCBA9876543210L){
            //reg_mprj_datal = 0xAB610000;
            }
            CMOS_OUT = 0xFFFFFFFFFFFFFFFFL;
            if (KEY != 0xFFFFFFFFFFFFFFFFL){
            //reg_mprj_datal = 0xAB610000;
            }
        }
        for (int j=0; j<200; j++); //doing a busy wait, I think. 
        reg_mprj_datal = 0xAB610000;
    }
	
	/*reg_mprj_datal = 0xAB600000;

    reg_mprj_slave = 0x01234567;
    reg_mprj_datal = 0xAB610000;
    if (reg_mprj_slave == 0x2B3D) {
        reg_mprj_datal = 0xAB610000;
    }*/
}