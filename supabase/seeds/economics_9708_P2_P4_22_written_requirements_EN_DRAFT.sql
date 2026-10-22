-- Reproducible private staging for 22 Economics 9708 P2/P4 written tasks.
-- This is an INTERNAL EN-ONLY DRAFT seed; NEVER publish, score or expose it.
-- Re-running does not overwrite an existing academic review or learner content.
INSERT INTO private.iclub_exam_core_written_tasks_v1
 (program_key,version_key,paper_code,task_key,task_version,questions,answer_requirements)
SELECT s->>'program_key',s->>'version_key',s->>'paper_code',
       s->>'task_key',s->>'task_version',
       s->'questions',s->'answer_requirements'
FROM jsonb_array_elements($iclub$[
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.A.a",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Define a shortage in a market."
    },
    "answer_requirements": {
      "en": [
        "State an accurate definition using quantity demanded and quantity supplied at a particular price."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.A.b",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Using the source, calculate the weekly shortage of vegetables at the maximum price in thousands of kilograms. Show your working."
    },
    "answer_requirements": {
      "en": [
        "Choose the appropriate source figures.",
        "Show the calculation and report the requested unit."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.A.c",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Explain, with reference to a correctly labelled demand-and-supply diagram where useful, how the fungal disease could affect the equilibrium price and quantity of vegetables if demand were unchanged."
    },
    "answer_requirements": {
      "en": [
        "Explain an adverse production shock with demand held constant.",
        "Explain the direction of the changes in equilibrium price and quantity.",
        "If using a diagram, label axes and initial/new market curves."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.A.d",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Analyse two reasons why a maximum price set below equilibrium might fail to improve the actual availability of vegetables."
    },
    "answer_requirements": {
      "en": [
        "Develop two economically distinct reasons rather than simply listing them.",
        "Link each reason to market incentives, imbalance and actual availability."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.A.e",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Explain why a fall in the inflation rate from 8% to 6% does not necessarily mean that the overall consumer price level is falling."
    },
    "answer_requirements": {
      "en": [
        "Distinguish a change in inflation from a decline in the overall price level.",
        "Use the stated rates accurately and recognise the difference between one product price and the consumer price index."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.A.f",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Evaluate whether removing the vegetable price ceiling would necessarily benefit low-income households."
    },
    "answer_requirements": {
      "en": [
        "Consider benefits from improved supply and access.",
        "Consider changes in affordability and distribution.",
        "Reach a conditional judgement linked to market responsiveness and household circumstances."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.B1.a",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Explain factors affecting the price elasticity of supply of an agricultural product."
    },
    "answer_requirements": {
      "en": [
        "Explain what price elasticity of supply measures.",
        "Develop mechanisms involving production time, spare capacity, storability and resource availability.",
        "Apply the explanation to agriculture."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.B1.b",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Assess whether a producer subsidy is always more effective than a maximum price in making essential food affordable."
    },
    "answer_requirements": {
      "en": [
        "Explain possible changes in supply, prices and affordability under a producer subsidy.",
        "Contrast with the effects of a binding maximum price.",
        "Evaluate costs, market response, distribution and conditions before a judgement."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.B2.a",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Explain how cross elasticity of demand differs for substitutes and complements."
    },
    "answer_requirements": {
      "en": [
        "Define and interpret cross elasticity of demand.",
        "Distinguish substitutes from complements using suitable relationships and examples."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.B2.b",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Assess whether knowing price elasticity of demand is sufficient for a government to predict revenue from an indirect tax."
    },
    "answer_requirements": {
      "en": [
        "Explain the relevance of demand responsiveness to indirect-tax outcomes.",
        "Analyse other relevant determinants including the tax rate, traded quantity and supply response.",
        "Evaluate whether PED alone is sufficient."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.C1.a",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Explain how an increase in government expenditure can influence aggregate demand and output."
    },
    "answer_requirements": {
      "en": [
        "Identify the aggregate-demand channel affected by government expenditure.",
        "Develop the link to output, considering spare capacity and multiplier conditions.",
        "Use appropriate economic terms or a clear AD/AS diagram where relevant."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.C1.b",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Assess whether supply-side measures are likely to be more effective than a rise in government spending in improving economic growth."
    },
    "answer_requirements": {
      "en": [
        "Explain distinct mechanisms of demand-side and supply-side measures.",
        "Compare short- and longer-term output effects and implementation constraints.",
        "Reach a conditional judgement reflecting economic circumstances."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.C2.a",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Explain two causes of a current account deficit."
    },
    "answer_requirements": {
      "en": [
        "Explain the meaning and relevant components of the current account.",
        "Develop two distinct economic mechanisms that may cause a deficit."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P2",
    "task_key": "P2.C2.b",
    "task_version": "economics_9708_P2_written_requirements_en_v1",
    "questions": {
      "en": "Assess the effectiveness of an exchange-rate depreciation in reducing a persistent current account deficit."
    },
    "answer_requirements": {
      "en": [
        "Explain possible effects of depreciation on export/import competitiveness and values.",
        "Analyse price elasticities, time lags and imported production inputs.",
        "Evaluate when depreciation may or may not reduce the deficit."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.A.a",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Calculate Nerava’s Year B trade balance in goods and services. Show the method and state whether it is a deficit or surplus."
    },
    "answer_requirements": {
      "en": [
        "Select the appropriate figures from the supplied source.",
        "Show the calculation and classify the resulting balance correctly."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.A.b",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Explain why the improvement in the goods and services trade balance cannot by itself establish whether Nerava has a current account surplus."
    },
    "answer_requirements": {
      "en": [
        "Distinguish the goods-and-services trade balance from the current account.",
        "Identify other current-account information needed before making a conclusion."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.A.c",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Analyse two channels through which depreciation could change Nerava’s trade balance over time. Refer to the source."
    },
    "answer_requirements": {
      "en": [
        "Analyse two distinct mechanisms affecting export/import prices, quantities or receipts.",
        "Use evidence from the source and recognise how effects may change over time."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.A.d",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Assess whether vocational training is likely to do more than exchange-rate intervention to improve Nerava’s long-run growth and external trade position."
    },
    "answer_requirements": {
      "en": [
        "Explain appropriate channels linking training and exchange-rate intervention to output, competitiveness and trade.",
        "Analyse relevant costs, time lags and source conditions.",
        "Develop a conditional and supported comparative judgement."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.B1",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Assess whether an oligopolistic market is necessarily less economically efficient than a perfectly competitive market."
    },
    "answer_requirements": {
      "en": [
        "Use relevant concepts of allocative, productive and dynamic efficiency.",
        "Compare important market characteristics and incentives.",
        "Analyse efficiency losses from market power and potential gains from economies of scale or innovation.",
        "Evaluate whether the claim holds in every case and justify the conclusion."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.B2",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Evaluate whether an indirect tax is the most effective government response to a negative externality arising from industrial production."
    },
    "answer_requirements": {
      "en": [
        "Apply relevant external-cost analysis to explain the market failure.",
        "Analyse likely effects and limitations of an indirect tax.",
        "Compare at least one defensible alternative intervention and reach a conditional judgement."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.C1",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Assess the extent to which monetary policy can achieve sustained economic growth in an open economy without worsening inflation."
    },
    "answer_requirements": {
      "en": [
        "Explain monetary-policy transmission through economic demand, interest rates and exchange rates.",
        "Distinguish short-run demand effects from sustained growth in productive capacity.",
        "Evaluate trade-offs, constraints, inflation and time lags in an open economy."
      ]
    }
  },
  {
    "program_key": "economics_9708",
    "version_key": "economics_2026_2028_v1",
    "paper_code": "P4",
    "task_key": "P4.C2",
    "task_version": "economics_9708_P4_written_requirements_en_v1",
    "questions": {
      "en": "Evaluate the view that real GDP per head should be the primary measure used to judge a country’s economic development."
    },
    "answer_requirements": {
      "en": [
        "Explain what real GDP per head captures and why it is used.",
        "Analyse limitations including inequality, wider welfare and sustainability.",
        "Compare with suitable additional development indicators and reach a supported judgement."
      ]
    }
  }
]$iclub$::jsonb) AS s
ON CONFLICT (program_key,version_key,task_key,task_version) DO NOTHING;
-- No release flags or approvals are touched.
