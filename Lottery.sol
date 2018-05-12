pragma solidity ^0.4.20;
pragma experimental ABIEncoderV2;

contract Lottery{
    
    uint lotteryTime = 400;
    uint purchaseTime = 200;
    
    uint lotteryGenesis;
    address winnerAddress;
    uint public winner = 0;
    uint lotteryCounter = 0;


    mapping(address=>Ticket[]) tickets;
    mapping(address=> bool) is_valid;
    mapping(address=>uint) ticket_order;
    mapping(uint=>address) ticketOwner;
    mapping(address=>uint) winnerReimbursment; 
    mapping(uint=>uint) lotteryBalance; //kacinci lotteryde ne kadar para gelmis onu tutuyor
    function Lottery() public{
        lotteryGenesis=block.number; // ilk contract creation zamaninda bir fark olusuyor onu egale etmek icin +1 yapiyoruz
    }
    
    struct Ticket{
        uint tip; // tip 1 ise full ticket, tip 2 ise half ticket, tip 3 ise quarter ticket
        bytes32 ticket_hash;
        uint N;
        bool isValidTicket;
    }
    /*
    *bytes32 val either random hash code or random number N, depending on the block number.
    */
    function purchase(bytes32 val) public payable returns (string){
        if(msg.value!=8 finney && msg.value!=4 finney && msg.value!=2 finney){
            revert();
        }else{
            if( block.number - lotteryGenesis >= lotteryTime){
                lotteryGenesis = block.number;
                winner = 0;
                lotteryCounter += 1;

            }
            if( block.number - lotteryGenesis <= purchaseTime){
                //TODO: create ticket, map to its adress
                Ticket memory t;
                if(msg.value == 0.008 ether){
                    t.tip = 1;
                }else if (msg.value == 0.004 ether){
                    t.tip = 2;
                }else if(msg.value == 0.002 ether){
                    t.tip = 3;
                }
                t.ticket_hash = val;
                tickets[msg.sender].push(t);

            }
            return "Purchase Successful";
        }
        return "Purchase is not successful";
    }
    
    function withdraw() public payable returns (string){
        string memory res = "hello";
        if(winnerReimbursment[msg.sender] == 0){
            throw;
            res = "You are not allowed to withdraw";
        }else{
            uint amount = winnerReimbursment[msg.sender];
            msg.sender.transfer(amount);
            winnerReimbursment[msg.sender] = winnerReimbursment[msg.sender]- amount;
            res = "Withdraw is Successful";
        }
        if( block.number - lotteryGenesis >= lotteryTime ){
            // lottery time control
            lotteryGenesis = block.number;
            lotteryCounter += 1;
            winner = 0;
        }
        return res;
    }
   
   function reveal(uint N) public payable returns (string){
        string memory result = "empty";
            //TODO burdaki if'te sadece Ticket'larin is_valid kismini false yapacaksin, senderin degil
            if( block.number - lotteryGenesis > purchaseTime){
                //TODO: create ticket, map to its adress
                bytes32 shah=keccak256(N,msg.sender);
                
                if(tickets[msg.sender][ticket_order[msg.sender]].ticket_hash == shah){
                   tickets[msg.sender][ticket_order[msg.sender]].isValidTicket = true; 
                    winner = winner ^ N; // wineer global numarasi ile gelen ticket XOR laniyor.
                    result = "Ÿour number has been retrieved, Good Luck :) ";
                }else{
                    tickets[msg.sender][ticket_order[msg.sender]].isValidTicket = false;
                    result = "Your number is not valid, sorry :( ";
                }
                tickets[msg.sender][ticket_order[msg.sender]].N=N;
                ticketOwner[N]=msg.sender;
                ticket_order[msg.sender]+=1;
                
            }
            // bu if revealin son adimi winner belirleme
           if( block.number - lotteryGenesis >= lotteryTime ){
                lotteryGenesis = block.number;
               //TODO is_valid false olmayan ticketlar arasinda Nleri XOR yapacaksin ve withdraw icin onay vereceksin
                winnerAddress = ticketOwner[winner];
                Ticket memory winnerTicket;
                // winnerin ticket arrayinde gez, ticketi bul
                for(uint i = 0;i<tickets[winnerAddress].length;i++){
                    if(tickets[winnerAddress][i].N==winner){
                        winnerTicket = tickets[winnerAddress][i];
                    }
                }
                
                //check lottery balance
                if(lotteryCounter == 0){
                    lotteryBalance[lotteryCounter] = address(this).balance;
                }else{
                    lotteryBalance[lotteryCounter] = address(this).balance - lotteryBalance[lotteryCounter-1];
                }
                
                if(winnerTicket.tip==1){
                    winnerReimbursment[winnerAddress]+=lotteryBalance[lotteryCounter] / 2;
                }else if(winnerTicket.tip==2){
                    winnerReimbursment[winnerAddress]+=lotteryBalance[lotteryCounter] / 4;
                }else if(winnerTicket.tip==3){
                    winnerReimbursment[winnerAddress]+=lotteryBalance[lotteryCounter] / 8;
                }
                //reset winner number
                winner = 0;
                lotteryCounter += 1;
                result = "Winner has been decided";
               
           }
           return result;
   }
   
   function getLotteryCounter() public view returns (uint){
       return lotteryCounter;
   }
    function getBlockNumber() public view returns  (uint256){
        return block.number;
    }   
    function getBalance() public view returns (uint){
         return address(this).balance / 1 finney;
    }
    function getWinnerNumber() public view returns (uint){
        return winner;
    }
    function getWinnerAddress() public view returns (address){
        return winnerAddress;
    }
   
    function getTimeInfo() public view returns(uint){
        if( block.number - lotteryGenesis > lotteryTime ){
            return block.number - lotteryGenesis - lotteryTime;
        }else{
            return block.number - lotteryGenesis;
        }
    }
    function getLotteryGenesis() public view returns(uint){
        return lotteryGenesis;
    }
    
    function getHashValue(uint N,address adr) public view returns(bytes32){
        return keccak256(N,adr);
    }
    function getWinnerReimbursmentInfo() public view returns (uint){
        return winnerReimbursment[msg.sender];
    }

  
}