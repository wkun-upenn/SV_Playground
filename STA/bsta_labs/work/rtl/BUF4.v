
module BUF4 (
   /*AUTOARG*/
   // Outputs
   CK0, Y, 
   // Inputs
   CK
);

   //==========================================================================
   //==========               Interface Signals                      ==========
   //==========================================================================
   // Declare all your Interface Signals in this section

   // Delayed versions of the input clock
   output CK0; // For use by latches & flops
   output Y;   // Sent to the next delay element in the chain

   // Inputs
   input  CK;  // Input clock from the previous delay element in the chain


   //==========================================================================
   //==========               Internal Signals                       ==========
   //==========================================================================
   // Declare all your Internal Signals in this section
   //
   // Signal Naming Convention
   // Signame = <UnitMnemonic><Functionality ID><SignalMnemonic><MicroPipeline>
   //               <PipeStageNum><Signal Type><Active Low><Buffered Mnemonic>



   //==========================================================================
   //==========           Beginning of Actual Logic                  ==========
   //==========================================================================


   // Below is a simplified abstract representation of the actual layout.
   // The below code is suitable for use in RTL simulation.
   // It will be replaced by a custom layout in the back-end flow.

   assign #2 CK0 = CK;
   assign #2 Y = CK;


endmodule // BUF4


//-----------------------------------------------------------------------------
// Modification history :
// Mon Jul 25 12:00:00 2002 : created
//
// $Log: BUF4.v,v $
// Revision 1.1  2002/07/26 18:32:22  chris
// Use separate delay chains for each superc & clkmaskc
//
