MCU=atmega328p # Select your MCU here. Arduino Uno has the atmega328p mcu. For the MCUs of other Arduino boards, please consult arduino.cc
CPU=16000000L # 16 MHz (arduino has an external clock, this should be the same on most Arduino boards)
SOURCES_PROJECT=AVRIRCCLI.cpp libs/SPI/SPI.cpp libs/Ethernet/Dns.cpp libs/Ethernet/EthernetClient.cpp libs/Ethernet/Ethernet.cpp libs/Ethernet/EthernetUdp.cpp libs/Ethernet/utility/socket.cpp libs/Ethernet/utility/w5100.cpp
PROJECT_NAME=AVRIRCCLI
PROGRAMMER=arduino # set your programmer here, I use the stk500. On the standard arduino isp it's "arduino"
PORT=/dev/ttyACM0 # set the port for the connection to your programmer here. Arduino sits at /dev/ttyACM0
AP_PATH=/home/dan/programming/active/ArduinoPure/
BAUDRATE=115200

CC=$(AP_PATH)tools/avr/bin/avr-gcc
CCP=$(AP_PATH)tools/avr/bin/avr-g++
AR=$(AP_PATH)tools/avr/bin/avr-ar rcs
OBJ=$(AP_PATH)tools/avr/bin/avr-objcopy
AVRDUDE=$(AP_PATH)tools/avrdude
AVRDUDEFLAGS=-c$(PROGRAMMER) -p$(MCU) -P$(PORT) -C$(AP_PATH)tools/avrdude.conf -b$(BAUDRATE)
EEPFLAGS=-O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0
HEXFLAGS=-O ihex -R .eeprom
CFLAGS=-c -g -Os -Wall -fno-exceptions -ffunction-sections -fdata-sections -mmcu=$(MCU) -DF_CPU=$(CPU) -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=101 -I$(AP_PATH)arduino -I$(AP_PATH)arduino/variants/standard -Ilibs/Ethernet -Ilibs/Ethernet/utility -Ilibs/SPI
LDFLAGS=-Os -Wl,--gc-sections -mmcu=$(MCU) -L$(AP_PATH)arduino -L$(AP_PATH) -lm
ARFILE=$(AP_PATH)arduino/core.a
OBJECTS_PROJECT=$(SOURCES_PROJECT:.cpp=.o)
SOURCES_ARDUINO_C=$(AP_PATH)arduino/wiring_digital.c $(AP_PATH)arduino/WInterrupts.c $(AP_PATH)arduino/wiring_pulse.c $(AP_PATH)arduino/wiring_analog.c $(AP_PATH)arduino/wiring.c $(AP_PATH)arduino/wiring_shift.c
OBJECTS_ARDUINO_C=$(SOURCES_ARDUINO_C:.c=.o)
SOURCES_ARDUINO_CPP=$(AP_PATH)arduino/CDC.cpp $(AP_PATH)arduino/Stream.cpp $(AP_PATH)arduino/HID.cpp $(AP_PATH)arduino/Tone.cpp $(AP_PATH)arduino/WMath.cpp $(AP_PATH)arduino/WString.cpp $(AP_PATH)arduino/new.cpp $(AP_PATH)arduino/main.cpp $(AP_PATH)arduino/HardwareSerial.cpp $(AP_PATH)arduino/IPAddress.cpp $(AP_PATH)arduino/Print.cpp $(AP_PATH)arduino/USBCore.cpp
OBJECTS_ARDUINO_CPP=$(SOURCES_ARDUINO_CPP:.cpp=.o)
OBJECTS=$(OBJECTS_PROJECT) $(OBJECTS_ARDUINO_C) $(OBJECTS_ARDUINO_CPP)
OBJECTS_CORE=$(OBJECTS_ARDUINO_C) $(OBJECTS_ARDUINO_CPP)
ELFCODE=$(join $(PROJECT_NAME),.elf)
EEPCODE=$(join $(PROJECT_NAME),.eep)
HEXCODE=$(join $(PROJECT_NAME),.hex)

all: clean $(SOURCES) $(ARFILE) $(ELFCODE) $(EEPCODE) $(HEXCODE)

$(ARFILE): $(OBJECTS)
	$(AR) $(ARFILE) $(OBJECTS)

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

$(ELFCODE): 
	$(CC) $(LDFLAGS) $(OBJECTS_PROJECT) $(ARFILE) -o $@

$(EEPCODE):
	$(OBJ) $(EEPFLAGS) $(ELFCODE) $@

$(HEXCODE):
	$(OBJ) $(HEXFLAGS) $(ELFCODE) $@

clean_obj:
	rm -rf $(OBJECTS) $(ARFILE)

clean_results:
	rm -rf $(ELFCODE) $(EEPCODE) $(HEXCODE)

clean: clean_obj clean_results

upload:
	$(AVRDUDE) $(AVRDUDEFLAGS) -Uflash:w:$(HEXCODE):i
