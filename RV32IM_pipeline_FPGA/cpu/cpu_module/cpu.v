// including the modules
//`include "../mux2to1_3bit.v"
//`include "../control_unit.v"
//`include "../alu.v"
//`include "../reg_file.v"

// `include "data_cache_memory.v"
// `include "ins_cache_memory.v"

//`include "../immediate_select.v"
//`include "../branch_select.v"
//`include "../mux2to1_32bit.v"
//`include "../mux4to1_32bit.v"
//`include "../stage3_forward_unit.v"
//`include "../stage4_forward_unit.v"

module cpu(PC, INSTRUCTION, CLK, RESET, memReadEn, memWriteEn, DATA_CACHE_ADDR, DATA_CACHE_DATA, DATA_CACHE_READ_DATA, DATA_CACHE_BUSY_WAIT,insReadEn, INS_CACHE_BUSY_WAIT, REGISTER_DEBUG_ADDR, REGISTER_DEBUG_DATA, ALU_DEBUG_OUT, DEBUG_CONTROL, REGISTER_DEBUG_LCD, DEGUB_INST, CLK_RAND_GEN, INTERUPT_SIGNAL, netInterfaceReadEn, netInterfaceWriteEn, NET_INTER_READ_DATA, NETWORK_STATUS);

    input [31:0] INSTRUCTION; //fetched INSTRUCTIONtructions
    input CLK, RESET, CLK_RAND_GEN; // clock and reset for the cpu
    input DATA_CACHE_BUSY_WAIT; // busy wait signal from the memory
    input INS_CACHE_BUSY_WAIT; // busy wait from the instruction memory
    input [31:0] DATA_CACHE_READ_DATA; // input from the memory read
    input [31:0] NET_INTER_READ_DATA; // input form the network interface
    output reg [31:0] PC; //programme counter
    output [3:0] memReadEn; // control signal to the data memory
    output [2:0] memWriteEn; // control signal to the data memory
    output reg insReadEn; // read enable for the instruction read
    output [31:0] DATA_CACHE_ADDR, DATA_CACHE_DATA; // output signal to the memory (address and the write data input)

    // for the network interface
    output netInterfaceReadEn, netInterfaceWriteEn;

    // for the interupt
    input INTERUPT_SIGNAL;
	
    // to debug the register
    output [31:0] REGISTER_DEBUG_DATA;
    output [5:0] ALU_DEBUG_OUT;
    input [4:0] REGISTER_DEBUG_ADDR;
    output [47:0] REGISTER_DEBUG_LCD; // register data for lcd

    output [6:0] DEBUG_CONTROL;
    output [31:0] DEGUB_INST;

    // input wire for the network interface status
    input [31:0] NETWORK_STATUS;

    // assign ALU_DEBUG_OUT = ALU_OUT;

    wire [31:0] alu_debug;
    assign ALU_DEBUG_OUT = PR_ALU_SELECT;
    assign DEGUB_INST = alu_debug;
    // assign DEBUG_CONTROL = {BRANCH_SELECT_OUT, PR_OPERAND1_SEL, PR_OPERAND2_SEL, OP1_HAZ_MUX_SEL, OP2_HAZ_MUX_SEL};

    wire FLUSH; 
    
    //     ************************** STAGE 1 **************************
//   data lines
    reg [31:0] PR_INSTRUCTION, PR_PC_S1;

    // structure
        // additional wires
        wire [31:0] PC_NEXT, PC_NEXT_FINAL, PC_NEXT_REGFILE;
        wire INTERUPT_PC_REG_EN;

        // additional registers
        reg [31:0] PC_PLUS_4;

        // units
        // TODO: ALU out should be defined later, Branch select out should be defined later
        mux2to1_32bit muxjump (PC_PLUS_4, ALU_OUT, PC_NEXT, BRANCH_SELECT_OUT);

        // interupt control unit
        wire JALR_SELECT_INTERRUPT;
        interupt_control ic (CLK, RESET, PC_NEXT, INTERUPT_SIGNAL, PC_NEXT_FINAL, PC_NEXT_REGFILE, INTERUPT_PC_REG_EN, JALR_SELECT_INTERRUPT, PR_INSTRUCTION[19:15]);


        // connections
        always @(posedge CLK)
        begin
            PC_PLUS_4 = PC + 4;
        end
    

//************************** STAGE 2 **************************
    // data lines
    reg [31:0] PR_PC_S2, PR_DATA_1_S2, PR_DATA_2_S2, PR_IMMEDIATE_SELECT_OUT;
    reg [4:0] PR_REGISTER_WRITE_ADDR_S2;
    // for the fowarding unit
    reg [4:0] REG_READ_ADDR1_S2, REG_READ_ADDR2_S2;

    // control lines
    reg [3:0] PR_BRANCH_SELECT_S2, PR_MEM_READ_S2;
    reg [5:0] PR_ALU_SELECT;
    reg PR_OPERAND1_SEL, PR_OPERAND2_SEL;
    reg [2:0] PR_MEM_WRITE_S2; 
    reg [1:0] PR_REG_WRITE_SELECT_S2;
    reg PR_REG_WRITE_EN_S2; 
    reg PR_NET_INTER_WRITE_S2, PR_NET_INTER_READ_S2;

    // structure
        // additionl wires
        wire [31:0] DATA1_S2, DATA2_S2, IMMEDIATE_OUT_S2; 
        wire [3:0] IMMEDIATE_SELECT;
        wire [3:0] BRANCH_SELECT, MEM_READ_S2;
        wire [5:0] ALU_SELECT;
        wire OPERAND1_SEL, OPERAND2_SEL;
        wire [2:0] MEM_WRITE_S2; 
        wire [1:0] REG_WRITE_SELECT_S2;
        wire REG_WRITE_EN_S2; 
        wire [12:0] RAND_NUM_GEN_OUT;

        // for the network interface
        wire NET_INTER_READ_S2, NET_INTER_WRITE_S2;

        // units

        // random number genertor module
        rand_num_gen rand_num_gen_module (CLK_RAND_GEN, RESET, RAND_NUM_GEN_OUT);

        //TODO: WRITE_DATA, WRITE_ADDR, WRITE_EN 
        reg_file myreg (REG_WRITE_DATA, 
                        DATA1_S2, 
                        DATA2_S2, 
                        PR_REGISTER_WRITE_ADDR_S4, 
                        PR_INSTRUCTION[19:15], 
                        PR_INSTRUCTION[24:20], 
                        PR_REG_WRITE_EN_S4, 
                        CLK, 
                        RESET,
                        REGISTER_DEBUG_DATA,
                        REGISTER_DEBUG_ADDR,
                        REGISTER_DEBUG_LCD,
                        RAND_NUM_GEN_OUT,
                        PC_NEXT_REGFILE,
                        INTERUPT_PC_REG_EN,
                        NETWORK_STATUS); //alu module

        immediate_select myImmediate (PR_INSTRUCTION, IMMEDIATE_SELECT, IMMEDIATE_OUT_S2);
        
        control_unit myControl (PR_INSTRUCTION, 
                                ALU_SELECT, 
                                REG_WRITE_EN_S2, 
                                MEM_WRITE_S2, 
                                MEM_READ_S2, 
                                BRANCH_SELECT, 
                                IMMEDIATE_SELECT, 
                                OPERAND1_SEL, 
                                OPERAND2_SEL, 
                                REG_WRITE_SELECT_S2, 
                                RESET,
                                DEBUG_CONTROL,
                                JALR_SELECT_INTERRUPT,
                                NET_INTER_WRITE_S2,
                                NET_INTER_READ_S2);

//************************** STAGE 3 **************************
    reg [31:0] PR_PC_S3, PR_ALU_OUT_S3, PR_DATA_2_S3;
    reg [4:0] PR_REGISTER_WRITE_ADDR_S3;
    // for the fowarding unit Stage 4
    reg [4:0] REG_READ_ADDR2_S3;

    // control lines
    reg [3:0] PR_MEM_READ_S3;
    reg [2:0] PR_MEM_WRITE_S3; 
    reg [1:0] PR_REG_WRITE_SELECT_S3;
    reg PR_REG_WRITE_EN_S3; 
    reg PR_NET_INTER_WRITE_S3, PR_NET_INTER_READ_S3;

    // structure
        // additional wires
        wire[31:0] ALU_IN_1, ALU_IN_2;
        wire[31:0] ALU_OUT;
        wire BRANCH_SELECT_OUT;
        wire[31:0] OP1_HAZ_MUX_OUT, OP2_HAZ_MUX_OUT;
        wire [1:0] OP1_HAZ_MUX_SEL, OP2_HAZ_MUX_SEL;

        assign FLUSH = BRANCH_SELECT_OUT;
        //TODO change the temp wires
        mux4to1_32bit oparand1_mux_haz(PR_DATA_1_S2, PR_ALU_OUT_S3, REG_WRITE_DATA, REG_WRITE_DATA_S5, OP1_HAZ_MUX_OUT, OP1_HAZ_MUX_SEL);        
        mux4to1_32bit oparand2_mux_haz(PR_DATA_2_S2, PR_ALU_OUT_S3, REG_WRITE_DATA, REG_WRITE_DATA_S5, OP2_HAZ_MUX_OUT, OP2_HAZ_MUX_SEL);        
        
        mux2to1_32bit oparand1_mux (OP1_HAZ_MUX_OUT, PR_PC_S2, ALU_IN_1, PR_OPERAND1_SEL);
        mux2to1_32bit oparand2_mux (OP2_HAZ_MUX_OUT, PR_IMMEDIATE_SELECT_OUT, ALU_IN_2, PR_OPERAND2_SEL);
        
        alu myAlu (ALU_IN_1, ALU_IN_2, ALU_OUT, PR_ALU_SELECT, alu_debug);
        branch_select myBranchSelect(OP1_HAZ_MUX_OUT, OP2_HAZ_MUX_OUT, PR_BRANCH_SELECT_S2, BRANCH_SELECT_OUT);

        // fowarding unit in stage 3
        //TODO: Netwrk interface stuff have to enter into the hazzaed unit
        stage3_forward_unit myStage3Fowarding (PR_MEM_WRITE_S2[2], 
                                               REG_READ_ADDR1_S2, 
                                               REG_READ_ADDR2_S2, 
                                               PR_OPERAND1_SEL, 
                                               PR_OPERAND2_SEL, 
                                               PR_REGISTER_WRITE_ADDR_S3, 
                                               PR_REG_WRITE_EN_S3, 
                                               PR_REGISTER_WRITE_ADDR_S4, 
                                               PR_REG_WRITE_EN_S4,  
                                               PR_REGISTER_WRITE_ADDR_S5, 
                                               PR_REG_WRITE_EN_S5, 
                                               OP1_HAZ_MUX_SEL, 
                                               OP2_HAZ_MUX_SEL);

//************************** STAGE 4 **************************
    // data lines
    reg [31:0] PR_PC_S4, PR_ALU_OUT_S4, PR_DATA_CACHE_OUT;
    reg [4:0] PR_REGISTER_WRITE_ADDR_S4;

    // control lines
    reg [1:0] PR_REG_WRITE_SELECT_S4;
    reg PR_REG_WRITE_EN_S4; 
    reg [3:0] PR_MEM_READ_S4;
    reg PR_NET_INTER_READ_S4;

    // structure
        // additional wires
        wire [31:0] PC_PLUS_4_2;
        wire HAZ_MUX_SEL;
        wire [31:0] HAZ_MUX_OUT;
        wire [31:0] DATA_READ_MUX_OUT;

        // units
        assign DATA_CACHE_DATA = HAZ_MUX_OUT;
        assign DATA_CACHE_ADDR = PR_ALU_OUT_S3;
        assign memWriteEn = PR_MEM_WRITE_S3;
        assign memReadEn = PR_MEM_READ_S3;
        assign netInterfaceWriteEn = PR_NET_INTER_WRITE_S3;
        assign netInterfaceReadEn = PR_NET_INTER_READ_S3;
        //TODO: Netwrk interface stuff have to enter into the hazzaed unit
        stage4_forward_unit stage4_forward_unit(REG_READ_ADDR2_S3, 
                                                PR_REGISTER_WRITE_ADDR_S4, 
                                                PR_MEM_WRITE_S3[2], 
                                                PR_MEM_READ_S4[3],
                                                PR_NET_INTER_WRITE_S3,
                                                PR_NET_INTER_READ_S4, 
                                                HAZ_MUX_SEL);

        mux2to1_32bit stage4_forward_unit_mux(PR_DATA_2_S3, PR_DATA_CACHE_OUT, HAZ_MUX_OUT, HAZ_MUX_SEL);

        mux2to1_32bit data_read_mux(DATA_CACHE_READ_DATA, NET_INTER_READ_DATA, DATA_READ_MUX_OUT, netInterfaceReadEn);
//************************** STAGE 5 **************************
    // EXTRA pipeline registers to handle the fowarding 
    // data lines
    reg [31:0] REG_WRITE_DATA_S5;
    reg [4:0] PR_REGISTER_WRITE_ADDR_S5;

    // control lines
    reg PR_REG_WRITE_EN_S5; 
    
    
    // structure
        // additional wires
        wire [31:0] REG_WRITE_DATA;

        // units
        // mux4to1_32bit regWriteSelMUX (PR_PC_S4, PR_ALU_OUT_S4, PR_DATA_CACHE_OUT, 32'b0, REG_WRITE_DATA, PR_REG_WRITE_SELECT_S4);
        mux4to1_32bit regWriteSelMUX (PR_DATA_CACHE_OUT, PR_ALU_OUT_S4, 32'b0, PR_PC_S4, REG_WRITE_DATA, PR_REG_WRITE_SELECT_S4);

        // connections

// register updating section
always @(posedge CLK) begin
    //#1
    if (RESET == 1'b1)
    begin
        // clearing the pipeline registers
        PR_INSTRUCTION = 32'b0;
        PR_PC_S1 = 32'b0;

        PR_PC_S2 = 32'b0;
        PR_DATA_1_S2 = 32'b0; 
        PR_DATA_2_S2 = 32'b0; 
        PR_IMMEDIATE_SELECT_OUT = 32'b0;
        
        PR_REGISTER_WRITE_ADDR_S2 = 5'b0;
        PR_BRANCH_SELECT_S2 = 4'b0; 
        PR_MEM_READ_S2 = 4'b0;
        PR_ALU_SELECT = 5'b0;
        PR_OPERAND1_SEL = 1'b0;
        PR_OPERAND2_SEL = 1'b0;
        PR_MEM_WRITE_S2 = 3'b0; 
        PR_REG_WRITE_SELECT_S2 = 2'b0;
        PR_REG_WRITE_EN_S2 = 1'b0; 
        PR_NET_INTER_WRITE_S2 = 1'b0;
        PR_NET_INTER_READ_S2 = 1'b0;

        PR_PC_S3 = 32'b0; 
        PR_ALU_OUT_S3 = 32'b0;
        PR_DATA_2_S3 = 32'b0;
        PR_REGISTER_WRITE_ADDR_S3 = 5'b0;
        PR_MEM_READ_S3 = 4'b0;
        PR_MEM_WRITE_S3 = 3'b0; 
        PR_REG_WRITE_SELECT_S3 = 2'b0;
        PR_REG_WRITE_EN_S3 = 1'b0; 
        PR_NET_INTER_READ_S3 = 1'b0;
        PR_NET_INTER_WRITE_S3 = 1'b0;

        PR_PC_S4 = 32'b0;
        PR_ALU_OUT_S4 = 32'b0;
        PR_DATA_CACHE_OUT = 32'b0;
        PR_REGISTER_WRITE_ADDR_S4 = 5'b0;
        PR_REG_WRITE_SELECT_S4 = 2'b0;
        PR_REG_WRITE_EN_S4 = 1'b0;
        PR_MEM_READ_S4 = 4'b0;
        PR_NET_INTER_READ_S4 = 1'b0;
    end
    else
    begin
        if (!(DATA_CACHE_BUSY_WAIT || INS_CACHE_BUSY_WAIT))
        begin
            if (FLUSH)
            begin
                //************************** STAGE 5 Tempary stage for the fowarding unit **************************
                REG_WRITE_DATA_S5 = REG_WRITE_DATA;
                PR_REGISTER_WRITE_ADDR_S5 = PR_REGISTER_WRITE_ADDR_S4;

                PR_REG_WRITE_EN_S5 = PR_REG_WRITE_EN_S4;

                //#0.001
                //************************** STAGE 4 **************************
                PR_REGISTER_WRITE_ADDR_S4 = PR_REGISTER_WRITE_ADDR_S3;
                PR_PC_S4 = PR_PC_S3;
                PR_ALU_OUT_S4 = PR_ALU_OUT_S3;
                PR_DATA_CACHE_OUT = DATA_CACHE_READ_DATA;
                
                PR_REG_WRITE_SELECT_S4  = PR_REG_WRITE_SELECT_S3;
                PR_REG_WRITE_EN_S4 = PR_REG_WRITE_EN_S3;
                PR_MEM_READ_S4 = PR_MEM_READ_S3;
                PR_NET_INTER_READ_S4 = PR_NET_INTER_READ_S3;
                
                //************** ************ STAGE 3 **************************
                //#0.001
                PR_REGISTER_WRITE_ADDR_S3 = PR_REGISTER_WRITE_ADDR_S2;
                PR_PC_S3 = PR_PC_S2;
                PR_ALU_OUT_S3 = ALU_OUT;
                PR_DATA_2_S3 = OP2_HAZ_MUX_OUT; 
                REG_READ_ADDR2_S3 = REG_READ_ADDR2_S2;   
                
                PR_MEM_READ_S3 = PR_MEM_READ_S2;
                PR_MEM_WRITE_S3 = PR_MEM_WRITE_S2;
                PR_NET_INTER_READ_S3 = PR_NET_INTER_READ_S2;
                PR_NET_INTER_WRITE_S3 = PR_NET_INTER_WRITE_S2;
                PR_REG_WRITE_SELECT_S3  = PR_REG_WRITE_SELECT_S2;
                PR_REG_WRITE_EN_S3 = PR_REG_WRITE_EN_S2;

                //************************** STAGE 2 **************************  
                //#0.001  
                PR_REGISTER_WRITE_ADDR_S2 = PR_INSTRUCTION[11:7]; // TODO: check the 11:7 value
                PR_PC_S2 = PR_PC_S1;
                PR_DATA_1_S2 = DATA1_S2;
                PR_DATA_2_S2 = DATA2_S2;
                PR_IMMEDIATE_SELECT_OUT = IMMEDIATE_OUT_S2;
                REG_READ_ADDR1_S2 = PR_INSTRUCTION[19:15];                
                REG_READ_ADDR2_S2 = PR_INSTRUCTION[24:20];

                PR_BRANCH_SELECT_S2 =  BRANCH_SELECT;
                PR_ALU_SELECT =  ALU_SELECT;
                PR_OPERAND1_SEL =  OPERAND1_SEL;
                PR_OPERAND2_SEL =  OPERAND2_SEL;
                PR_MEM_READ_S2 =  4'b0000;
                PR_MEM_WRITE_S2  =  3'b000;
                PR_NET_INTER_READ_S2 = 1'b0;
                PR_NET_INTER_WRITE_S2 = 1'b0;
                PR_REG_WRITE_SELECT_S2 = REG_WRITE_SELECT_S2;
                PR_REG_WRITE_EN_S2 = 1'b0; 

                //************************** STAGE 1 **************************
                //#0.001
                PR_INSTRUCTION = 32'b0;
                PR_PC_S1 = PC; //PC_PLUS_4;
                
            end
            else 
            begin
                //************************** STAGE 5 Tempary stage for the fowarding unit **************************
                REG_WRITE_DATA_S5 = REG_WRITE_DATA;
                PR_REGISTER_WRITE_ADDR_S5 = PR_REGISTER_WRITE_ADDR_S4;

                PR_REG_WRITE_EN_S5 = PR_REG_WRITE_EN_S4;

                //#0.001
                //************************** STAGE 4 **************************
                PR_REGISTER_WRITE_ADDR_S4 = PR_REGISTER_WRITE_ADDR_S3;
                PR_PC_S4 = PR_PC_S3;
                PR_ALU_OUT_S4 = PR_ALU_OUT_S3;
                PR_DATA_CACHE_OUT = DATA_READ_MUX_OUT;
                
                PR_REG_WRITE_SELECT_S4  = PR_REG_WRITE_SELECT_S3;
                PR_REG_WRITE_EN_S4 = PR_REG_WRITE_EN_S3;
                PR_MEM_READ_S4 = PR_MEM_READ_S3;
                PR_NET_INTER_READ_S4 = PR_NET_INTER_READ_S3;
                
                //************** ************ STAGE 3 **************************
                //#0.001
                PR_REGISTER_WRITE_ADDR_S3 = PR_REGISTER_WRITE_ADDR_S2;
                PR_PC_S3 = PR_PC_S2;
                PR_ALU_OUT_S3 = ALU_OUT;
                PR_DATA_2_S3 = OP2_HAZ_MUX_OUT; 
                REG_READ_ADDR2_S3 = REG_READ_ADDR2_S2;   
                
                PR_MEM_READ_S3 = PR_MEM_READ_S2;
                PR_MEM_WRITE_S3 = PR_MEM_WRITE_S2;
                PR_NET_INTER_READ_S3 = PR_NET_INTER_READ_S2;
                PR_NET_INTER_WRITE_S3 = PR_NET_INTER_WRITE_S2;
                PR_REG_WRITE_SELECT_S3  = PR_REG_WRITE_SELECT_S2;
                PR_REG_WRITE_EN_S3 = PR_REG_WRITE_EN_S2;

                //************************** STAGE 2 **************************  
                //#0.001  
                PR_REGISTER_WRITE_ADDR_S2 = PR_INSTRUCTION[11:7]; // TODO: check the 11:7 value
                PR_PC_S2 = PR_PC_S1;
                PR_DATA_1_S2 = DATA1_S2;
                PR_DATA_2_S2 = DATA2_S2;
                PR_IMMEDIATE_SELECT_OUT = IMMEDIATE_OUT_S2;
                REG_READ_ADDR1_S2 = PR_INSTRUCTION[19:15];                
                REG_READ_ADDR2_S2 = PR_INSTRUCTION[24:20];

                PR_BRANCH_SELECT_S2 =  BRANCH_SELECT;
                PR_ALU_SELECT =  ALU_SELECT;
                PR_OPERAND1_SEL =  OPERAND1_SEL;
                PR_OPERAND2_SEL =  OPERAND2_SEL;
                PR_MEM_READ_S2 =  MEM_READ_S2;
                PR_MEM_WRITE_S2  =  MEM_WRITE_S2;
                PR_NET_INTER_READ_S2 = NET_INTER_READ_S2;
                PR_NET_INTER_WRITE_S2 = NET_INTER_WRITE_S2;
                PR_REG_WRITE_SELECT_S2 = REG_WRITE_SELECT_S2;
                PR_REG_WRITE_EN_S2 = REG_WRITE_EN_S2; 

                //************************** STAGE 1 **************************
                //#0.001
                PR_INSTRUCTION = INSTRUCTION;
                PR_PC_S1 = PC; //PC_PLUS_4;
            end
        end
    end
end

// PC update with the clock edge
// always @ (posedge CLK) begin     
always @ (*) begin     
    if (RESET == 1'b1) 
        begin
            PC = -4; // reset the pc counter
            insReadEn = 1'b0; // disable the read enable signal of the instruction memory
        end
    else 
    begin
        //insReadEn = 1'b0;
        //#1
        if (!(DATA_CACHE_BUSY_WAIT || INS_CACHE_BUSY_WAIT)) 
        begin 
            PC = PC_NEXT_FINAL;       // increment the pc
            insReadEn = 1'b1; // enable read from the instruction memory
        end
    end
end

endmodule