-- Run on the PLATFORM (mdms) database, the one that holds pf_api_resource / pf_resource_access.
-- Adds prefix rows for every erp-qm-service URL family that is not covered yet.
-- The gateway lets a request through when its path CONTAINS an OPEN row's endpoint,
-- so one prefix row covers all URLs under it (including ones with ids in the path).
-- Safe to re-run: existing ids / role mappings are skipped.

INSERT INTO public.pf_api_resource
    (id, type, module, apiendpoint, enabled, accesstype, createdby, lastmodifiedby, createdtime, lastmodifiedtime)
SELECT v.id, 'API', 'qm', v.ep, true, 'OPEN',
       'd4755057-561b-4eea-af2b-e18c9818e138', 'd4755057-561b-4eea-af2b-e18c9818e138',
       (extract(epoch from now()) * 1000)::bigint, (extract(epoch from now()) * 1000)::bigint
FROM (VALUES
    ('RESAPI9911', '/erp-qm-service/api/v1/repairs'),
    ('RESAPI9912', '/erp-qm-service/api/v1/conditional-use'),
    ('RESAPI9913', '/erp-qm-service/api/v1/calibration-records'),
    ('RESAPI9914', '/erp-qm-service/api/v1/labels'),
    ('RESAPI9915', '/erp-qm-service/api/v1/audit'),
    ('RESAPI9916', '/erp-qm-service/api/v1/certificates'),
    ('RESAPI9917', '/erp-qm-service/api/v1/oot-assessments'),
    ('RESAPI9918', '/erp-qm-service/api/v1/quality-holds'),
    ('RESAPI9919', '/erp-qm-service/api/v1/external-service-requests'),
    ('RESAPI9920', '/erp-qm-service/api/v1/reports')
) AS v(id, ep)
ON CONFLICT (id) DO NOTHING;

-- Map the new resources to the role you already use for the other rows.
INSERT INTO public.pf_resource_access
    (uuid, role_id, pf_resource_id, createdby, lastmodifiedby, createdtime, lastmodifiedtime)
SELECT md5(random()::text || clock_timestamp()::text || r.id)::uuid, 'COMPANY.PS_HEAD', r.id,
       'd4755057-561b-4eea-af2b-e18c9818e138', 'd4755057-561b-4eea-af2b-e18c9818e138',
       extract(epoch from now())::bigint, extract(epoch from now())::bigint
FROM public.pf_api_resource r
WHERE r.id BETWEEN 'RESAPI9911' AND 'RESAPI9920'
  AND NOT EXISTS (
      SELECT 1 FROM public.pf_resource_access a
      WHERE a.pf_resource_id = r.id AND a.role_id = 'COMPANY.PS_HEAD');

-- Check:
-- SELECT id, apiendpoint, accesstype FROM public.pf_api_resource WHERE id LIKE 'RESAPI99%' ORDER BY id;
