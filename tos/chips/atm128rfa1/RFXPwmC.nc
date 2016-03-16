generic configuration RFXPwmC() {
	provides {
		interface GeneralPWM;
	}
	uses {
		interface GeneralIO as PinA;
		interface GeneralIO as PinB;
		interface GeneralIO as PinC;
		interface HplAtmegaCounter<uint16_t> as Counter;
		interface HplAtmegaCompare<uint16_t> as Compare[uint8_t channel];
	}
}
implementation {

	// TODO implementation

}
