const {
  loadFixture
} = require("@nomicfoundation/hardhat-network-helpers");
const { utils } = require("ethers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
var should = require('chai').should() //actually call the function

describe("Deploy",()=>{
  async function votingFixture(){
    const election =await (await ethers.getContractFactory('VotingApp')).deploy();
    const [owner,candidate,candidate2] =await ethers.getSigners();
    return {election,owner,candidate,candidate2};
  }
  describe("Check Autorizations",()=>{
    it("Only owner can launch election",async()=>{
    const{election,owner,candidate}=await loadFixture(votingFixture);
    await expect(election.connect(candidate).startElection(5,"Add swap functionality",["yay","nay"])).to.be.revertedWithCustomError(election,"callerIsNotOwner");
    await expect(election.connect(owner).startElection(1,"Add swap functionality",["yay","nay"]));  
    });
    it("Only owner can add new users",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await expect(election.connect(candidate).addVoter("Taneristique",candidate2.address)).to.be.revertedWithCustomError(election,"callerIsNotOwner");
      await expect(election.connect(owner).addVoter("Taneristique",candidate2.address));
    });
    it("Only owner can ban a user",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).addVoter("Taneristique",candidate2.address);
      await expect(election.connect(candidate).banUser(candidate2.address)).to.be.revertedWithCustomError(election,"callerIsNotOwner");
      await expect(election.connect(owner).banUser(candidate2.address));
    });
    it("Only users can cast their votes",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["yay","nay"]);
      await election.connect(owner).addVoter("Taneristique",candidate2.address);
      await expect(election.connect(owner).vote("yay"));
      await expect(election.connect(candidate2).vote("nay"));
      await expect(election.connect(candidate).vote("yay")).to.be.revertedWithCustomError(election,"userNotRegistered");
    });
    it("A banned user can't cast vote",async()=>{
      const{election,owner,candidate}=await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["yay","nay"]);
      await election.connect(owner).addVoter("Taneristique",candidate.address);
      await election.connect(owner).banUser(candidate.address)
      await expect(election.connect(candidate).vote("yay")).to.be.revertedWithCustomError(election,"userBanned");
    });
    it("Only owner can transfer ownership",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await expect(election.connect(owner).renounceOwnership(candidate2.address));
      await expect(election.connect(candidate).renounceOwnership(candidate2.address)).to.be.revertedWithCustomError(election,"callerIsNotOwner");
    })
    it("Owner has no authorization to set a new election before current one has finished",async()=>{
      const{election,owner}=await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["yay","nay"]);
      await expect(election.connect(owner).startElection(2,"Add borrowing functionality",["accept","reject"])).to.be.revertedWithCustomError(election,"electionDidNotFinish");
    })
    it("Result cannot be monitored before current election has finished",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["yay","nay"]);
      await election.connect(owner).addVoter("Taneristique",candidate.address);
      await election.connect(owner).addVoter("taneristique",candidate2.address);
      await election.connect(owner).vote("nay");
      await election.connect(candidate).vote("yay");
      await election.connect(candidate2).vote("yay");
      await expect(election.connect(owner).votingResult()).to.be.revertedWithCustomError(election,"electionDidNotFinish");
    });
  });
  describe("Voting Result",()=>{
    it("If the number of votes are equal first vote in options array win",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["ok","no"]);
      await election.connect(owner).addVoter("Taneristique",candidate.address);
      await election.connect(owner).addVoter("taneristique",candidate2.address);
      await election.connect(candidate).vote("ok");
      await election.connect(candidate2).vote("no");
      if(await election.connect(owner).electionTimer()==0){
        await expect(election.connect(owner).votingResult()).to.be.eq("ok");
      }
    })
    it("Voting result cannot be manipulated with reEntrancy even if a user calls vote function multiple times",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["ok","no"]);
      await election.connect(owner).addVoter("Taneristique",candidate.address);
      await election.connect(owner).addVoter("taneristique",candidate2.address);
      //candidates attempt to vote 14 times in total
      for(let i=0;i<7;i++){
        await election.connect(candidate).vote("ok");
        await election.connect(candidate2).vote("no");
      }
      return Promise.resolve(election.connect(owner).countVotes()).should.eventually.equal(2n);
    });
  });
  describe("Logs",()=>{
    it("Old election topics and decision can be viewed by users",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["ok","no"]);
      await election.connect(owner).addVoter("Taneristique",candidate.address);
      await election.connect(owner).addVoter("taneristique",candidate2.address);
      await election.connect(candidate).vote("ok");
      await election.connect(candidate2).vote("no");
      if(await election.connect(owner).electionTimer()==0){
        await election.connect(owner).startElection(1,"Decrease borrowing fee to %0.75",["agree","reject"]);
        await election.connect(owner).vote("agree");
        await election.connect(candidate).vote("reject");
        await election.connect(candidate2).vote("agree");
      }
      if(await election.connect(owner).electionTimer()==0){
        //decision of first election must be "ok"
        //to get it use showOldElectionResult(uint256) function
        //to get topic use showOldElectionTopic(uint256) function
        await expect(election.connect(owner).showOldElectionResult(0)).to.be.eq("ok");
        await expect(election.connect(owner).showOldElectionTopic(0)).to.be.eq("Add swap functionality");
        await expect(election.connect(owner).showOldElectionResult(0)).to.be.eq("agree");
        await expect(election.connect(owner).showOldElectionTopic(0)).to.be.eq("Decrease borrowing fee to %0.75");
      }
    });
    it("Owner can view the address of registered users",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).addVoter("Taneristique",candidate.address);
      await election.connect(owner).addVoter("Taneristique2",candidate2.address);
      let _registeredUsers=[candidate.address,candidate2.address];
      console.log(await election.connect(owner).showRegisteredUsers());
    });
    it("Options can be viewed by people",async()=>{
      const{election,owner,candidate} = await loadFixture(votingFixture);
      await election.connect(owner).startElection(1,"Add swap functionality",["ok","no"]);
      console.log(await election.connect(candidate).showOptions());
    });
    it("Name of users are logged and can be view as calling showVoter(address) function",async()=>{
      const{election,owner,candidate,candidate2}=await loadFixture(votingFixture);
      await election.connect(owner).addVoter("Taneristique",candidate.address);
      return Promise.resolve(election.connect(owner).showVoter(candidate.address)).should.eventually.equal("Taneristique");
    });
  });
})