require 'digest'

module NOMADIC
  module Bank
    class Vault
      include Redis::Objects
      sorted_set :account
      hash_key :txs
      def initialize i
        @id = i
        Redis::Set.new('vaults') << @id
      end
      def id; @id; end
      def tx f, t, a
        at = Time.now.utc.to_f.to_s.gsub('.', '')[0..15]
        self.account.decr(f, a.to_f)
        self.account.incr(t, a.to_f)
        ff, tt = Wallet.new(f), Wallet.new(t)
        ff.vault.decr(@id, a)
        ff.txs[at] = "-#{a} #{t}"
        tt.vault.incr(@id, a)
        tt.txs[at] = "+#{a} #{f}"
        self.txs[Time.now.utc.to_f.to_s.gsub('.', '')] = "#{f} #{t} #{a}"
      end
      def balance
        self.account.members(with_scores: true)
      end
    end
    class Wallet
      include Redis::Objects
      sorted_set :vault
      hash_key :txs
      def initialize i
        @id = i
      Redis::Set.new('wallets') << @id
      end
      def id; @id; end
      def balance
        self.vault.members(with_scores: true).to_h
      end
    end
    def self.record tx, h={}
      Redis::HashKey.new("tx:#{tx}").bulk_set(h)
    end
    class Block
      
      attr_reader :index
      attr_reader :timestamp
      attr_reader :transactions
      attr_reader :transactions_count
      attr_reader :previous_hash
      attr_reader :hash
      
      def initialize(index, transactions, previous_hash)
        @index              = index
        @timestamp          = Time.now.utc
        @transactions       = transactions
        @transactions_count = transactions.size
        @previous_hash      = previous_hash
        @hash               = calc_hash
        
        ##
        # handle tx in Vault 
        [transactions].flatten.each do |h|
          #puts "#{h}"
          Vault.new(h[:what]).tx(h[:from], h[:to], h[:qty])
        end
        
      end
      
      def hash
        @hash
      end
      
      def to_h
        {
          index: @index,
          timestamp: @timestamp,
          transactions: @transactions,
          previous: @previous,
          hash: @hash
        }
      end
      
      def calc_hash
        sha = Digest::SHA256.new
        sha.update( @index.to_s +
                    @timestamp.to_s +
                    @transactions_count.to_s +
                    @transactions.to_s +
                    @previous_hash )
        sha.hexdigest
      end
      
      ##  ruby note: the splat operator (that is, *) turns list of passed in transactions into array
      def self.first( *transactions )    # create genesis (big bang! first) block
        ## uses index zero (0) and arbitrary previous_hash ("0")
        Block.new( 0, transactions, "0" )
      end
      
      def self.next( previous, *transactions )
        Block.new( previous.index+1, transactions, previous.hash )
      end
      
    end  # class Block
    class Chain
      def initialize *tx
        @last = Block.first(tx)
        Bank.record @last.hash, @last.to_h
        @chain = [ @last ]
      end
      def add *tx
        @last = Block.next(@last, tx)
        Bank.record @last.hash, @last.to_h
        @chain << @last
      end
      def blocks
        @chain
      end
    end
    class Branch
      def initialize t
        @t = t
        @c = Chain.new({ from: "Bank", to: "Bank", what: @t, qty: 0 })
      end
      def history
        @c
      end
      def borrow amt
        @c.add from: 'World', to: 'Bank', what: @t, qty: amt
      end
      def tx h={}
        @c.add from: h[:from] || 'Bank', to: h[:to] || 'Bank', what: @t, qty: h[:qty] || 0, payload: h[:payload] 
      end
    end
    def self.of k
      {
        branch: Branch.new(k),
        vault: Vault.new(k)
      }
    end
    def self.account u
      Wallet.new(u)
    end
    def self.ledger
      w, v = {}, {}
      Redis::Set.new('wallets').members.each {|e| w[e] = Wallet.new(e).balance }
      Redis::Set.new('vaults').members.each {|e| v[e] = Vault.new(e).balance }
      { vault: v, wallet: w }
    end
  end
end


  
