module seg_dec(
    num,
    a_g



);
input[3:0]      num;
output[6:0]     a_g;

reg [6:0]   a_g;
always @(num)begin
    case(num)
    4'd0:
    begin
        a_g<=7'b111_1110;    
    end
     4'd2:
    begin
        a_g<=7'b111_1110;    
    end
    default:
    begin
        
    end
    endcase
end



endmodule