<script lang="ts">
  import Button from 'fpdao-ui/components/Button.svelte';
  import Modal from 'fpdao-ui/components/Modal.svelte';

  let modalOpen = localStorage.getItem('disclaimer-accepted') !== 'true';

  async function accept() {
    modalOpen = false;
    localStorage.setItem('disclaimer-accepted', 'true');
  }
</script>

{#if modalOpen}
<div class="p-10">
  <Modal title="Disclaimer" toggleModal={() => {}} closable={false}>
    <div class="flex gap-3 flex-col flex-1 justify-center items-center">
      <div class="whitespace-pre-line">
        Definitions.

        - <b>Planting</b> is delegating or locking Flowers on a platform developed by Flower Power team in the ICP blockchain for a certain period by getting Rewards; SEED tokens.
        - <b>SEED</b> is an unregulated form of utility token.
        - <b>Extract</b> is a status stating that the asset that has been planted will enter an unstaking event and will stop generating rewards (30 days delay). You can either choose to replant or fully extract the Flower by entering at your own discretion your digital wallet address you want your asset to be sent when the extracting period is fully dissolved.
        - <b>Withdrawing</b> is sending your planting rewards, SEED tokens, to a digital wallet specified at your own discretion and risk.


        Disclaimer.

        1. You acknowledge and agree that you designate garden.fpdao.app for the Planting & SEED token production services at your sole risk. The Services are provided on an “as-is” and “as-available” basis and, to the maximum extent permitted by Law, Flower Power Team disclaim all representations, warranties, and conditions regarding the Services provided and your use thereof, including any warranties or conditions of merchantability, merchantable quality, durability, fitness for a particular purpose, non-infringement, title, quiet enjoyment or quiet possession and those arising at Law, or from a course of dealing or usage of trade.
        Flower Power Team and any entities and individuals officially involved with the Flower Power Team do not represent or warrant that the Planting Services and SEED tokens will meet your requirements, expectations or desired outcomes, will operate without interruptions, be error-free or virus-free, that results obtained from the Planting Services will be timely, accurate, reliable or current, or that any or all deficiencies can be found or corrected. Flower Power Team does not represent or warrant that the Planting Staking Services are legal for use by you in your Place of Residence.

        2. Utility tokens such as SEED are unregulated forms of digital assets. However, regulation, interpretation, and laws vary by jurisdiction.
        Utility tokens involve and relate to the development and use of experimental software, technologies, and business models that may not come to fruition or achieve the objectives specified in the information provided connected to the project (e.G. As set out in the SEEDs tokenomic document).

        3. SEED tokens are utility tokens and represent a high risk to any holder. SEEDs should only be exchanged (in the purpose determined by the tokenomic document), sold, bought and held by those with substantial technical knowledge and by persons that feel competent in respect of the utility of the SEED tokens.
        Careful due diligence should be undertaken on the objective of the Flower Power Team, any entities and individuals officially involved with the Flower Power Team and with full understanding that holding SEED tokens may not ultimately result in a valuable token and the value of any contributions made to acquire, exchange, sell, SEED tokens may be subject to total loss.

        4. garden.fpdao.app does not offer custodial or fiduciary services to you, and does not hold your SEED tokens as your custodian or on your behalf. Your planted Flowers and SEED token balance is not a deposit, checking or savings account, and it is not covered by insurance against losses. Flowers and SEEDs staked using this platform are not insured by any private or governmental insurance plan or financial protection plan or financial compensation scheme (including any financial ombudsman).

        5. Before entering into any transaction and using Flower Power services such as Planting and SEEDs production you should ensure that you understand and have made an independent assessment of the suitability and appropriateness of a transaction into which you are entering and the nature and extent of your exposure to risk of loss in light of your own objectives, financial and operational resources and other relevant circumstances.

        6. When connecting your wallet, entering garden.fpdao.app and using Flower Power services such as Planting Flowers (BTC Flower, ETH Flower, ICP Flower, BTC Flower Gen 2.0) and SEEDs production you are solely responsible for establishing, providing or procuring, maintaining and supporting any operating environment, software and hardware, digital wallets (including, hardware wallets), facilities, equipment and telecommunications and internet connections necessary to use the Flower Power platform.

        7. You must have an understanding of digital wallets usage and maintain best industry practices in respect of security of your wallet and associated private keys utilised in Planting Flowers and managing SEEDs. You acknowledge that the Flower Power team and any entities and individuals officially involved with the Flower Power Team do not maintain your private keys neither the addresses of your digital wallets and cannot provide any assistance in their recovery, should they be lost, misspelled, destroyed, or stolen.
        Flower Power team is not responsible for any Loss you may suffer if your private keys to the wallets used are lost, destroyed or stolen.
        Flower Power team is not responsible for any Loss you may suffer if any informations, like wallet addresses, you are giving while using our services and/or transferring assets are misspelled, wrong or lost.
      </div>
      <Button style="w-auto px-20 py-8 h-10 mt-10 rounded-[55px]" on:click={accept}>
        Accept
      </Button>
      <div>&nbsp;</div>
    </div>
  </Modal>
  </div>
{/if}